#if FALSE
namespace Wanamics.Start.GenJournalLines;

using System.Reflection;
using Microsoft.Finance.GeneralLedger.Journal;

xmlport 87101 "WanaStart Import Balance"
{
    Caption = 'WanaStart Import Balance';
    Direction = Import;
    FieldDelimiter = '<None>';
    FieldSeparator = '|';
    Format = VariableText;
    TextEncoding = UTF8;

    schema
    {
        textelement(RootNodeName)
        {
            tableelement(ImportLine; "wanaStart Import FR Line")
            {
                textelement(CompteNum) { }
                textelement(CompteLib) { }
                textelement(_Amount) { }
                textelement(_ShortcutDimension1Code) { MinOccurs = Zero; }
                textelement(_ShortcutDimension2Code) { MinOccurs = Zero; }

                trigger OnPreXmlItem()
                var
                    MapSourceCode: Record "wanaStart Map Source Code";
                begin
                    Default.TestField("Document No.");
                    Default.TestField("Posting Date");
                    Default.TestField("Description");
                    MapSourceCode."From Source Name" := 'Opening Balance';
                    if MapSourceCode.Insert() then;
                end;

                trigger OnBeforeInsertRecord()
                begin
                    if not FirstlineSkipped then begin
                        FirstlineSkipped := true;
                        currXMLport.Skip();
                    end;
                    LineNo += 1;
                    ImportLine."Line No." := LineNo;
                    ImportLine.EcritureNum := Default."Document No.";
                    ImportLine.EcritureDate := Default."Posting Date";
                    if CompteNum <> MapAccount."From Account No." then
                        if not MapAccount.Get(CompteNum, '') then begin
                            MapAccount.Init();
                            MapAccount."From Account No." := CompteNum;
                            MapAccount."From Account Name" := CompteLib;
                            MapAccount.Insert();
                        end;
                    ImportLine.CompteNum := CompteNum;
                    ImportLine.EcritureLib := Default.Description;
                    ImportLine.Amount := ToDecimal(_Amount);
                    if ImportLine.Amount > 0 then
                        ImportLine.Debit := ImportLine.Amount
                    else
                        ImportLine.Credit := -ImportLine.Amount;
                    ImportLine."_Shortcut Dimension 1 Code" := _ShortcutDimension1Code;
                    ImportLine."_Shortcut Dimension 2 Code" := _ShortcutDimension2Code;
                end;
            }
        }
    }
    requestpage
    {
        SaveValues = true;
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DocumentNo; Default."Document No.")
                    {
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the document number for the journal lines.';
                        TableRelation = "Gen. Journal Line";
                        ApplicationArea = All;
                    }
                    field(PostingDate; Default."Posting Date")
                    {
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date for the journal lines.';
                        ApplicationArea = All;
                    }
                    field(Description; Default.Description)
                    {
                        Caption = 'Description';
                        ToolTip = 'Specifies the description for the journal lines.';
                        ApplicationArea = All;
                    }
                }
            }
        }
    }
    var
        FirstlineSkipped: Boolean;
        LineNo: Integer;
        TypeHelper: Codeunit "Type Helper";
        Default: Record "Gen. Journal Line";
        MapAccount: Record "WanaStart Map Account";

    procedure ToDecimal(pText: Text) ReturnValue: Decimal
    begin
        if pText <> '' then
            Evaluate(ReturnValue, pText);
    end;
}
#endif
