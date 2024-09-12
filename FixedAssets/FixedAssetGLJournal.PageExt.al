pageextension 87101 "wan Fixed Asset G/L Journal " extends "Fixed Asset G/L Journal"
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
                RunObject = codeunit "wan Import Fixed Assets";
            }
        }
    }
}
