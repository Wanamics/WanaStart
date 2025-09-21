pageextension 87101 "WanaStart FA G/L Journal " extends "Fixed Asset G/L Journal"
{
    actions
    {
        addlast(processing)
        {
            action(WanaStart)
            {
                Caption = 'WanaStart';
                Image = Import;
                ApplicationArea = All;
                RunObject = codeunit "WanaStart Import Fixed Assets";
            }
        }
    }
}
