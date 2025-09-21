page 87102 "WanaStart Map Source Codes"
{
    Caption = 'Map Source Codes';
    PageType = List;
    SourceTable = "WanaStart Map Source Code";
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
                // field("Bal. Account No."; Rec."Bal. Account No.") { }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group") { }
                field("WanaStart Source Posting Type"; Rec."WanaStart Posting Type") { }
                field("Skip"; Rec.Skip) { }
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
                    ImportLine: Record "wanaStart Import Line";
                begin
                    Rec.TestField("Document No.", Rec."Document No."::"From Line");
                    ImportLine.SetRange(JournalCode, Rec."From Source Code");
                    Codeunit.Run(Codeunit::"WanaStart Import Line Set Doc.", ImportLine);
                end;
            }
            action(SetVATAccountAmount)
            {
                Caption = 'Set VAT Account Amount';
                trigger OnAction()
                var
                    Selection: Record "wanaStart Map Source Code";
                begin
                    CurrPage.SetSelectionFilter(Selection);
                    Report.RunModal(Report::"WanaStart Set VAT Account Amt.", false, false, Selection);
                end;
            }
        }
        area(Promoted)
        {
            actionref(SetDocumentNoPromoted; SetDocumentNo) { }
        }
    }
}
