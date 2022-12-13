pageextension 87109 "wanaStart Data Administration" extends "Data Administration"
{
    actions
    {
        AddLast(DataCleanup)
        {
            action(wanaStartCleanUp)
            {
                ApplicationArea = All;
                Caption = 'Clean Data Before GoLive';
                Image = DeleteAllBreakpoints;
                RunObject = report "wanaStart Clean Data";
            }
        }
    }
}
