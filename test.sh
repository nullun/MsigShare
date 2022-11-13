#!/usr/bin/env bash

SB=~/sandbox/sandbox
GOAL="goal"

ACCT1=$(${GOAL} account list | head -n 1 | tail -n 1 | awk '{print $3}' | tr -d '\r')
ACCT2=$(${GOAL} account list | head -n 2 | tail -n 1 | awk '{print $3}' | tr -d '\r')

# Deploy
APP_ID=$(${GOAL} app method \
  --create \
  --from ${ACCT1} \
  --method "deploy(uint8,uint8)uint64" \
  --approval-prog approval.teal \
  --clear-prog clear.teal \
  --global-byteslices 8 --global-ints 11 \
  --local-byteslices 16 --local-ints 0 \
  --arg 0 \
  --arg 1 \
  | grep 'succeeded with output' \
  | awk '{print $6}' \
  | tr -d '\r')

# Add Account (index 0)
${GOAL} app method \
  --app-id ${APP_ID} \
  --from ${ACCT1} \
  --method "addAccount(uint8,account)void" \
  --arg 0 \
  --arg ${ACCT1}

# Send Algo to application account
APP_ACCT=$(${GOAL} app info \
  --app-id ${APP_ID} \
  | grep 'Application account' \
  | awk '{print $3}' \
  | tr -d '\r')
${GOAL} clerk send -a 2000000 -f ${ACCT1} -t ${APP_ACCT}

# Add Transaction
${GOAL} app method \
  --app-id ${APP_ID} \
  -f ${ACCT1} \
  --method "addTransaction(uint8,byte[])void" \
  --arg 0 \
  --arg '[137,163,102,101,101,205,3,232,162,102,118,54,163,103,101,110,170,115,97,110,100,110,101,116,45,118,49,162,103,104,196,32,62,160,54,224,241,86,88,161,168,82,24,155,226,96,177,129,96,148,87,115,64,251,176,126,168,207,75,52,214,222,160,95,162,108,118,205,4,30,164,110,111,116,101,196,8,161,26,133,211,79,58,253,210,163,114,99,118,196,32,2,208,34,127,26,75,138,99,106,166,160,189,202,161,161,255,94,142,249,222,102,175,109,111,106,54,145,176,35,9,45,7,163,115,110,100,196,32,2,208,34,127,26,75,138,99,106,166,160,189,202,161,161,255,94,142,249,222,102,175,109,111,106,54,145,176,35,9,45,7,164,116,121,112,101,163,112,97,121]' \
  --box 'str:txn0'

# Set Signatures
${GOAL} app method \
  --app-id ${APP_ID} \
  --from ${ACCT1} \
  --method "setSignatures(byte[][])void" \
  --on-completion "OptIn" \
  --arg '[[181,83,175,235,49,237,82,29,116,85,84,246,46,116,35,222,8,148,122,31,207,175,254,163,30,169,41,221,243,22,177,111,160,162,41,202,161,215,134,80,120,143,47,46,167,49,13,6,191,34,156,198,193,157,5,175,195,105,81,162,214,150,48,1]]'

# Clear Signatures
${GOAL} app method \
  --app-id ${APP_ID} \
  --from ${ACCT1} \
  --method "clearSignatures()void" \
  --on-completion "CloseOut"

# Add Account (index 1)
${GOAL} app method \
  --app-id ${APP_ID} \
  --from ${ACCT1} \
  --method "addAccount(uint8,account)void" \
  --arg 1 \
  --arg ${ACCT1}

# Replace Account (index 1)
${GOAL} app method \
  --app-id ${APP_ID} \
  --from ${ACCT1} \
  --method "addAccount(uint8,account)void" \
  --arg 1 \
  --arg ${ACCT2}

# Remove Account (index 0)
${GOAL} app method \
  --app-id ${APP_ID} \
  --from ${ACCT1} \
  --method "removeAccount(uint8)void" \
  --arg 0

# Remove Account (index 1)
${GOAL} app method \
  --app-id ${APP_ID} \
  --from ${ACCT1} \
  --method "removeAccount(uint8)void" \
  --arg 1

# Remove Transaction
${GOAL} app method \
  --app-id ${APP_ID} \
  --from ${ACCT1} \
  --method "removeTransaction(uint8)void" \
  --arg 0 \
  --box "str:txn0"

# Destroy
${GOAL} app method \
  --app-id ${APP_ID} \
  --from ${ACCT1} \
  --method "destroy()void" \
  --on-completion "DeleteApplication"

