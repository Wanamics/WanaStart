permissionset 87100 "WANASTART"
{
    Assignable = true;
    Caption = 'WanaStart';
    Permissions = table "WanaStart Map Account" = X,
        tabledata "WanaStart Map Account" = RIMD,
        table "WanaStart Map Source Code" = X,
        tabledata "WanaStart Map Source Code" = RIMD,
        table "WanaStart Direct Posting Buf." = X,
        tabledata "WanaStart Direct Posting Buf." = RMID,
        table "wanaStart Import Line" = X,
        tabledata "wanaStart Import Line" = RIMD,
        report "WanaStart Check Direct Posting" = X,
        report "WanaStart Clean Data" = X,
    // codeunit "wanaStart Gen. Journal Excel" = X,
    // codeunit "wanaStart Import FR Setup" = X,
        codeunit "wanaStart Apply Applies-to ID" = X,
        codeunit "WanaStart Map Create Accounts" = X,
        codeunit "WanaStart Import FR" = X,
        codeunit "WanaStart Map Suggest Setup" = X,
        page "WanaStart Map Accounts" = X,
        page "WanaStart Map Account Update" = X,
        page "WanaStart Map Source Codes" = X,
        // report "WanaStart M&A Exp. G/L Entries" = X,
        codeunit "WanaStart Send to Journal" = X,
        codeunit "WanaStart Import Line Split" = X,
        page "WanaStart Import Check VAT" = X,
        page "WanaStart Import Lines Details" = X,
        page WanaStart = X;
    // report "wan Apply Cust. Applies-to ID" = X,
    // report "wan Apply Vendor Applies-to ID" = X,
    // query "wan Apply Cust. Applies-to ID" = X,
    // query "wan Apply Vendor Applies-to ID" = X,
    // report "wan Apply Empl. Applies-to ID" = X,
    // query "wan Apply Empl. Applies-to ID" = X;
}