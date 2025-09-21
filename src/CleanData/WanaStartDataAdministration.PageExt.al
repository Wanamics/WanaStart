#if FALSE
pageextension 87109 "WanaStart Data Administration" extends "Data Administration"
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
                RunObject = report "WanaStart Clean Data";
            }
        }
    }
}
#endif
