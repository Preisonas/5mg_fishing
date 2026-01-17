# Analysis of PC Freezing Issues

Based on the provided screenshots of the component modification tool:

## Identified Cause
The **Custom CPU Build** setting is identified as the likely cause of PC freezing.

## Evidence
The tool explicitly states under the "Custom CPU Build" toggle:
> "*Use this build in case you have an older Intel CPU and the software freezes or bluescreens your computer.*"

## Recommendation
If the user is experiencing PC freezing or "Blue Screen of Death" (BSOD) and has an older Intel CPU, they should **enable** the "Custom CPU Build" option.

## Other Notes
The "Callback" feature also carries a warning ("*Only enable if instructed by developer / support staff*"), implying it could cause instability if used incorrectly, but the freezing issue is specifically linked to the CPU build option in the tool's description.
