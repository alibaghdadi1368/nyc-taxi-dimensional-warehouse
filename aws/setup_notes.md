# AWS Setup Notes

This document describes exactly how the AWS side of this project was configured:
one S3 bucket, one scoped IAM policy, and one IAM role that Snowflake assumes
through a Storage Integration - with **no AWS access keys ever hardcoded**
anywhere in this repository.

If you want to reproduce this project with your own AWS account, follow the
steps below in order.

---

## 0. Region

All AWS resources in this project live in **`eu-west-1` (Europe – Ireland)**.

> ⚠️ Your Snowflake account must be created on **AWS**, in the **same region**,
> otherwise you will incur cross-region data transfer charges when Snowflake
> reads from S3. See the main `README.md` for the Snowflake side of the setup.

---

## 1. Create the S3 Bucket

1. Open the **AWS Console** → confirm the region selector (top-right) is set
   to **Europe (Ireland) eu-west-1**.
2. Go to **S3** → **Create bucket**.
3. **Bucket name:** choose a globally unique name, e.g. `your-name-portfolio-snowflake-2026`.
4. **AWS Region:** `Europe (Ireland) eu-west-1`.
5. **Object Ownership:** leave as default (ACLs disabled).
6. **Block Public Access settings:** keep **all four boxes checked** (bucket
   stays fully private - Snowflake connects via IAM role, not public access).
7. **Bucket Versioning:** **Disable**.
8. **Default encryption:** leave as default (SSE-S3).
9. Click **Create bucket**.

### 1.1 Create the folder structure

Inside the new bucket, create two prefixes (folders):

```
raw/zones/
raw/trips/
```

### 1.2 Add a lifecycle rule (cost hygiene)

To avoid ever being charged for abandoned uploads:

1. Open the bucket → **Management** tab → **Create lifecycle rule**.
2. Rule name: `cleanup-incomplete-uploads`.
3. Rule scope: **Apply to all objects in the bucket**.
4. Under lifecycle rule actions, check:
   **"Delete expired object delete markers or incomplete multipart uploads"**
   → **Delete incomplete multipart uploads** → **7** days.
5. Save.

---

## 2. Create the IAM Policy

This policy grants access to **exactly one bucket** - nothing broader.

1. Go to **IAM** → **Policies** → **Create policy**.
2. Switch to the **JSON** tab and paste the contents of
   [`iam_policy.json`](./iam_policy.json) (also shown below), replacing
   `YOUR_BUCKET_NAME` with your actual bucket name.
3. Click **Next**, name it `snowflake-s3-access-policy`, and **Create policy**.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME"
    }
  ]
}
```

---

## 3. Create the IAM Role (temporary trust, fixed in Step 5)

Snowflake needs to *assume* a role to read/write the bucket. Because
Snowflake generates its own IAM user ARN and external ID only *after* the
integration exists in Snowflake, this role is created in two passes.

### 3.1 First pass  -  placeholder trust

1. Go to **IAM** → **Roles** → **Create role**.
2. **Trusted entity type:** `AWS account`.
3. Select **This account** (a temporary placeholder  -  this gets replaced
   in Step 5).
4. Check **Require external ID** and enter a placeholder value, e.g. `0000000000`.
5. **Next** → attach the `snowflake-s3-access-policy` created in Step 2.
6. **Next** → name the role `snowflake_s3_role` → **Create role**.

### 3.2 Record the Role ARN

Open the newly created role and copy its **ARN**
(`arn:aws:iam::<account_id>:role/snowflake_s3_role`)  -  you'll need it in Step 4.

---

## 4. Create the Storage Integration in Snowflake

Run this in Snowsight (see the main `sql/01_setup/` scripts for full context):

```sql
USE ROLE ACCOUNTADMIN;

CREATE STORAGE INTEGRATION s3_portfolio_int
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = '<role_arn_from_step_3.2>'
  STORAGE_ALLOWED_LOCATIONS = ('s3://YOUR_BUCKET_NAME/');

DESC INTEGRATION s3_portfolio_int;
```

From the `DESC INTEGRATION` output, copy two values:

| Property | Example |
|---|---|
| `STORAGE_AWS_IAM_USER_ARN` | `arn:aws:iam::444455556666:user/xyz-snowflake-user` |
| `STORAGE_AWS_EXTERNAL_ID` | `AB12345_SFCRole=2_xxxxxxxxxxxxxxxxxxxxxxx=` |

---

## 5. Fix the IAM Role Trust Policy (second pass)

This is the step that makes the connection actually secure: instead of
trusting "this AWS account" (the placeholder from Step 3), the role now
trusts **only** Snowflake's specific IAM user, and only when it presents
the correct external ID.

1. Go back to **IAM** → **Roles** → `snowflake_s3_role` → **Trust relationships** tab.
2. Click **Edit trust policy**.
3. Replace the contents with [`trust_policy.json`](./trust_policy.json)
   (also shown below), substituting the two values from Step 4.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "STORAGE_AWS_IAM_USER_ARN_FROM_SNOWFLAKE"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "STORAGE_AWS_EXTERNAL_ID_FROM_SNOWFLAKE"
        }
      }
    }
  ]
}
```

4. **Update policy**.

At this point, only Snowflake's specific IAM user - and only when it also
provides the matching external ID - can assume this role. No one else can,
even if they somehow learned the role's ARN.

---

## 6. Create the External Stage and Validate

Back in Snowsight:

```sql
USE DATABASE portfolio_db;
USE SCHEMA raw;

CREATE STAGE s3_raw_stage
  STORAGE_INTEGRATION = s3_portfolio_int
  URL = 's3://YOUR_BUCKET_NAME/raw/'
  FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

-- Should return without error (empty list is fine before you upload files)
LIST @s3_raw_stage;
```

If this returns `Access Denied`, double-check the ARN and external ID
pasted into the trust policy in Step 5 - that's the most common source
of a broken connection.

---

## 7. Local Credentials for Uploading Data (separate from the role above)

The `snowflake_s3_role` above is used **only by Snowflake** - roles don't
have access keys. To run `python/upload_to_s3.py` from your own machine,
create a separate IAM **user**:

1. **IAM** → **Users** → **Create user** → name it e.g. `local-upload-user`.
2. Do **not** grant AWS Management Console access - this user is for
   programmatic (CLI/SDK) access only.
3. Attach the same `snowflake-s3-access-policy` from Step 2.
4. Open the user → **Security credentials** → **Create access key** →
   use case **Command Line Interface (CLI)**.
5. Download the generated `.csv` - this is the only time the secret key
   is shown.
6. Locally, run:
   ```bash
   aws configure
   # AWS Access Key ID:     <from the .csv>
   # AWS Secret Access Key: <from the .csv>
   # Default region name:   eu-west-1
   # Default output format: json
   ```

⚠️ These keys are **never** committed to this repository. They live only
in your local `~/.aws/credentials` file, which Git never sees.

---

## 8. Teardown (cost & security hygiene)

Once you're done exploring this project, remove everything so nothing
keeps costing money or sitting around as a live credential:

```bash
# 1. Empty and delete the S3 bucket (via Console: select all objects → Delete,
#    then delete the bucket itself)

# 2. Delete the IAM role
#    IAM → Roles → snowflake_s3_role → Delete

# 3. Delete the IAM policy
#    IAM → Policies → snowflake-s3-access-policy → Delete

# 4. Deactivate and delete the local upload user's access key,
#    then delete the user itself
#    IAM → Users → local-upload-user → Security credentials → deactivate/delete key
#    IAM → Users → local-upload-user → Delete user
```

IAM roles, policies, and users cost nothing to keep, but deleting the
access key and the user removes a live credential that no longer needs
to exist once the project is finished.

---

## Summary of what was created

| Resource | Name | Purpose |
|---|---|---|
| S3 Bucket | `your-bucket-name` (region `eu-west-1`) | Landing zone for raw taxi + zone data |
| IAM Policy | `snowflake-s3-access-policy` | Least-privilege access to the bucket only |
| IAM Role | `snowflake_s3_role` | Assumed by Snowflake via Storage Integration |
| IAM User | `local-upload-user` | Used only locally to run the upload script |
| Snowflake object | `s3_portfolio_int` (Storage Integration) | Secure bridge between Snowflake and S3 |
| Snowflake object | `s3_raw_stage` (External Stage) | Where `COPY INTO` reads files from |
