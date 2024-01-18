permissionset 87100 "WANASTART"
{
    Assignable = true;
    Caption = 'WanaStart';
    Permissions = table "wanaStart Map Account" = X,
        tabledata "wanaStart Map Account" = RIMD,
        table "wanaStart Map Source Code" = X,
        tabledata "wanaStart Map Source Code" = RIMD,
        table "wanaStart Direct Posting Buf." = X,
        tabledata "wanaStart Direct Posting Buf." = RMID,
        table "wanaStart Import FR Line" = X,
        tabledata "wanaStart Import FR Line" = RIMD,
        report "wanaStart Check Direct Posting" = X,
        report "wanaStart Clean Data" = X,
        // codeunit "wanaStart Gen. Journal Excel" = X,
        // codeunit "wanaStart Import FR Setup" = X,
        report "wan Apply Cust. Applies-to ID" = X,
        report "wan Apply Vendor Applies-to ID" = X,
        codeunit "wanaStart Apply Applies-to ID" = X,
        codeunit "wanaStart Create Accounts" = X,
        codeunit "wanaStart Import FR" = X,
        codeunit "wanaStart Suggest Setup" = X,
        page "wanaStart Map Accounts" = X,
        page "wanaStart Map Account Update" = X,
        page "wanaStart Map Source Codes" = X,
        query "wan Apply Cust. Applies-to ID" = X,
        query "wan Apply Vendor Applies-to ID" = X;
}