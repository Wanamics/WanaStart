page 87103 "wan Import Lines Details"
{
    ApplicationArea = All;
    Caption = 'Import Lines Details';
    PageType = CardPart;
    SourceTable = "wanaStart Import FR Line";

    layout
    {
        area(content)
        {
            repeater(Repeater)
            {
                Caption = 'General';

                field(CompteNum; Rec.CompteNum)
                {
                }
                field(Amount; Rec.Amount)
                {
                }
            }
        }
    }
}
