pageextension 81910 "wanaStart Chart of Accounts" extends "Chart of Accounts"
{
    actions
    {
        addlast(processing)
        {
            action(CheckDirectPosting)
            {
                ApplicationArea = All;
                Caption = 'Check Direct Posting';
                Image = CheckLedger;
                RunObject = report "wanaStart Check Direct Posting";
            }
        }
    }
}
