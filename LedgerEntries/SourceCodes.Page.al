page 87102 "wanaStart Source Codes"
{
    Caption = 'WanaStart : Source Codes';
    PageType = List;
    SourceTable = "wanaStart Source Code";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("From Source Code"; Rec."From Source Code")
                {
                    ApplicationArea = All;
                }
                field("From Source Name"; Rec."From Source Name")
                {
                    ApplicationArea = All;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = All;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = All;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = All;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = All;
                }
                field(Skip; Rec.Skip)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
