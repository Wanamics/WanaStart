page 87106 "wanaStart Import Lines"
{
    ApplicationArea = All;
    Caption = 'Import Lines';
    PageType = List;
    SourceTable = "wanaStart Import FR Line";
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Line No."; Rec."Line No.")
                {
                    Width = 5;
                }
                field(JournalCode; Rec.JournalCode)
                {
                    Width = 5;
                }
                field(EcritureNum; Rec.EcritureNum)
                {
                    Width = 6;
                }
                field(EcritureDate; Rec.EcritureDate)
                {
                    Width = 6;
                }
                field(CompteNum; Rec.CompteNum)
                {
                    Width = 8;
                }
                field(CompAuxNum; Rec.CompAuxNum)
                {
                    Width = 8;
                }
                field(PieceRef; Rec.PieceRef)
                {
                    Width = 8;
                }
                field(Debit; Rec.Debit)
                {
                    Visible = false;
                    Width = 8;
                }
                field(Credit; Rec.Credit)
                {
                    Visible = false;
                    Width = 8;
                }
                field(Amount; Rec.Amount)
                {
                    Width = 8;
                }
                // field("Vat Amount"; VATAmount)
                // {
                //     BlankZero = true;
                //     Width = 8;
                // }
                field("VAT %"; Rec."VAT %")
                {
                    Width = 5;
                }
                field(Open; Rec.Open)
                {
                    Visible = false;
                }
                field(PieceDate; Rec.PieceDate)
                {
                    Width = 6;
                    Visible = false;
                }
                field(EcritureLib; Rec.EcritureLib)
                {
                }
                field(EcritureLet; Rec.EcritureLet)
                {
                    Visible = false;
                }
            }
        }
        area(FactBoxes)
        {
            part(Details; "wan Import Lines Factbox")
            {
                Caption = 'Details';
                ApplicationArea = All;
                SubPageLink =
                    JournalCode = field(JournalCode),
                    EcritureNum = field(EcritureNum),
                    EcritureDate = field(EcritureDate),
                    PieceRef = field(PieceRef);
            }
        }
    }
    // // actions
    // // {
    // //     area(Navigation)
    // //     {
    // //         action(ShowDocument)
    // //         {
    // //             Caption = 'Show Document';
    // //             Image = ShowList;
    // //             RunObject = page "wanaStart Import Lines";
    // //             RunPageLink =
    // //                 JournalCode = field(JournalCode),
    // //                 EcritureNum = field(EcritureNum),
    // //                 EcritureDate = field(EcritureDate),
    // //                 PieceRef = field(PieceRef);
    // //         }
    // //     }
    // }

    // var
    //     VATPercent: Decimal;
    //     VATAmount: Decimal;

}
