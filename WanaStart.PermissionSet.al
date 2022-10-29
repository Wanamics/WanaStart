permissionset 81900 "WANASTART"
{
    Assignable = true;
    Caption = 'WanaStart';
    Permissions =
        table "wanaStart Account" = X,
        tabledata "wanaStart Account" = RIMD,
        table "wanaStart Source Code" = X,
        tabledata "wanaStart Source Code" = RIMD,
        table "wanaStart Direct Posting Buf." = X,
        tabledata "wanaStart Direct Posting Buf." = RMID,
        report "wanaStart Check Direct Posting" = X;
}
