namespace Wanamics.WanaStart;

using Microsoft.Finance.GeneralLedger.Journal;
using System.IO;

report 87102 "WanaStart Import Balance"
{
    Caption = 'WanaStart Import Balance';
    ProcessingOnly = true;
    ApplicationArea = All;
    // dataset
    // {
    // dataitem(wanaStartImportLine; "wanaStart Import FR Line")
    // {
    //     trigger OnPreDataItem()
    //     begin

    //     end;

    //     trigger OnAfterGetRecord()
    //     var
    //         MapAccount: Record "wanaStart Map Account";
    //     begin
    //     end;

    //     trigger OnPostDataItem()
    //     var
    //         MapSourceCode: Record "WanaStart Map Source Code";
    //     begin
    //     end;
    // }
    // }


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

    trigger OnPreReport()
    var
        DeleteLines: Label 'Do you want to delete %1 previous lines?';
    begin
        if not ImportLine.IsEmpty then
            if not Confirm(DeleteLines, false, ImportLine.Count) then
                exit
            else
                ImportLine.DeleteAll();
        StartDateTime := CurrentDateTime;
        Default.TestField("Document No.");
        Default.TestField("Posting Date");
        Default.TestField("Description");
        ExcelImport();
    end;

    trigger OnPostReport()
    var
        DoneMsg: Label '%1 lines imported in %2.';
        MapSourceCode: Record "wanaStart Map Source Code";
    begin
        MapSourceCode."From Source Name" := 'Opening Balance';
        if MapSourceCode.Insert() then;
        Message(DoneMsg, ImportLine.Count, CurrentDateTime - StartDateTime);
    end;

    var
        StartDateTime: DateTime;
        ImportLine: Record "wanaStart Import Line";
        Default: Record "Gen. Journal Line";

    local procedure ExcelImport()
    var
        IStream: InStream;
        FileName: Text;
        ExcelBuffer: Record "Excel Buffer" temporary;
        Next: Integer;
    begin
        if UploadIntoStream('', '', '', FileName, IStream) then begin
            ExcelBuffer.OpenBookStream(IStream, ExcelBuffer.SelectSheetsNameStream(IStream));
            ExcelBuffer.ReadSheet();
            ExcelBuffer.SetFilter("Row No.", '>1');
            if ExcelBuffer.FindSet then
                repeat
                    ImportLine.Init();
                    ImportLine."Line No." := ExcelBuffer."Row No.";
                    ImportLine.EcritureNum := Default."Document No.";
                    ImportLine.EcritureDate := Default."Posting Date";
                    repeat
                        case ExcelBuffer."Column No." of
                            1:
                                ImportLine.CompteNum := ExcelBuffer."Cell Value as Text";
                            2:
                                ImportLine.EcritureLib := ExcelBuffer."Cell Value as Text";
                            3:
                                ImportLine.Amount := ToDecimal(ExcelBuffer."Cell Value as Text");
                            4:
                                ImportLine."_Shortcut Dimension 1 Code" := ExcelBuffer."Cell Value as Text";
                            5:
                                ImportLine."_Shortcut Dimension 2 Code" := ExcelBuffer."Cell Value as Text";
                        end;
                        Next := ExcelBuffer.Next;
                    until (Next = 0) or (ExcelBuffer."Row No." <> ImportLine."Line No.");
                    InsertLine();
                until Next = 0;
        end;
    end;

    local procedure InsertLine()
    var
        MapAccount: Record "wanaStart Map Account";
    begin
        if not MapAccount.Get(ImportLine.CompteNum, '') then begin
            MapAccount."From Account No." := ImportLine.CompteNum;
            MapAccount."From Account Name" := ImportLine.EcritureLib;
            MapAccount.Insert();
        end;
        ImportLine.EcritureLib := Default.Description;
        if ImportLine.Amount > 0 then
            ImportLine.Debit := ImportLine.Amount
        else
            ImportLine.Credit := -ImportLine.Amount;
        ImportLine.Insert();
    end;

    procedure ToDecimal(pText: Text) ReturnValue: Decimal
    begin
        if pText <> '' then
            Evaluate(ReturnValue, pText);
    end;
}
