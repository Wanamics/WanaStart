page 87102 "wanaStart Map Source Codes"
{
    Caption = 'Map Source Codes';
    PageType = List;
    SourceTable = "wanaStart Map Source Code";
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("From Source Code"; Rec."From Source Code") { Editable = false; }
                field("From Source Name"; Rec."From Source Name") { Editable = false; }
                field("Source Code"; Rec."Source Code") { }
                field("Bal. Account No."; Rec."Bal. Account No.") { }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group") { }
                field("Gen. Posting Type"; Rec."Gen. Posting Type") { }
                field(Skip; Rec.Skip) { }
                field("Unique Document No."; Rec."Start") { }
                field("No. of Lines"; Rec."No. of Lines") { }
            }
        }
    }
}
