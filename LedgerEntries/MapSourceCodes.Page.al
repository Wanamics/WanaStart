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
                field("From Source Code"; Rec."From Source Code") { }
                field("From Source Name"; Rec."From Source Name") { }
                field("No. of Lines"; Rec."No. of Lines") { }
                field("No. of Open Lines"; Rec."No. of Open Lines") { }
                field("Source Code"; Rec."Source Code") { }
                // field("VAT Account No. Filter"; Rec."VAT Account No. Filter") { }
                field("Bal. Account No."; Rec."Bal. Account No.") { }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group") { }
                field("Gen. Posting Type"; Rec."Gen. Posting Type") { }
                field(Skip; Rec.Skip) { }
                // field("PieceRef as Document No."; Rec."PieceRef as Document No.") { }
                field("Document No."; Rec."Document No.") { }
                field("External Document No."; Rec."External Document No.") { }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(SetDocumentNo)
            {
                Caption = 'Set Document No.';
                trigger OnAction()
                var
                    ImportLine: Record "wanaStart Import FR Line";
                // Rec2: Record "wanaStart Map Source Code";
                begin
                    Rec.TestField("Document No.", Rec."Document No."::"From Line");
                    ImportLine.SetRange(JournalCode, Rec."From Source Code");
                    // Rec2.SetRange("From Source Code", Rec."From Source Code");
                    // Report.RunModal(Report::"WanaStart Set Document No.", true, false, ImportLine);
                    Codeunit.Run(Codeunit::"WanaStart Import Line Set Doc.", ImportLine);
                end;
            }
        }
        area(Promoted)
        {
            actionref(SetDocumentNoPromoted; SetDocumentNo) { }
        }
    }
}
