#!/bin/sh

WEBHOOK=""

gcloud functions deploy approval_trigger \
  --trigger-topic clouddeploy-approvals \
  --runtime ruby27 \
  --source . \
  --set-env-vars "GOOGLE_CHAT_CALLBACK=${WEBHOOK}"
