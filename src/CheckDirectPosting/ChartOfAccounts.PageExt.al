pageextension 87105 "WanaStart Chart of Accounts" extends "Chart of Accounts"
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
                RunObject = report "WanaStart Check Direct Posting";
            }
        }
    }
}
