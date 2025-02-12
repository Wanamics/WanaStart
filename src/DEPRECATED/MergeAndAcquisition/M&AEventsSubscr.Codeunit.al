#if FALSE
namespace Wanamics.WanaStart;

using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using Microsoft.HumanResources.Payables;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.Dimension;
codeunit 87133 "WanaStart M&A Events Subscr."
{
    SingleInstance = true;

    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        ShortcutDimCode: array[8] of Code[20];

    [EventSubscriber(ObjectType::Report, Report::"WanaStart M&A Exp. G/L Entries", OnAfterSetLoadFields, '', false, false)]
    local procedure OnAfterSetLoadFields(var GLEntry: Record "G/L Entry")
    var
        GLSetup: Record "General Ledger Setup";
        DimMgt: Codeunit DimensionManagement;
    begin
        GLEntry.AddLoadFields("Dimension Set ID");
        VendorLedgerEntry.SetLoadFields("External Document No.", "Closed by Entry No.");
        CustLedgerEntry.SetLoadFields("External Document No.", "Closed by Entry No.");
        EmployeeLedgerEntry.SetLoadFields("Closed by Entry No.");
        GLSetup.Get();
        DimMgt.GetGLSetup(ShortcutDimCode);
    end;

    [EventSubscriber(ObjectType::Report, Report::"WanaStart M&A Exp. G/L Entries", OnAppendHeaders, '', false, false)]
    local procedure OnAppendHeaders(var pText: Text)
    var
        i: Integer;
    begin
        pText := '|ExternalDocumentNo|ClosedByEntryNo|DimensionSetID';
        for i := 1 to 8 do
            pText += '|' + ShortcutDimCode[i];
    end;

    [EventSubscriber(ObjectType::Report, Report::"WanaStart M&A Exp. G/L Entries", OnAppendColumns, '', false, false)]
    local procedure OnAppendColumns(pGLEntry: Record "G/L Entry"; var pText: Text);
    var
        ExternalDocumentNo: Code[35];
        ClosedByEntryNo: Integer;
    begin
        case pGLEntry."Source Type" of
            pGLEntry."Source Type"::Vendor:
                begin
                    if VendorLedgerEntry.Get(pGLEntry."Entry No.") then begin
                        ExternalDocumentNo := VendorLedgerEntry."External Document No.";
                        ClosedByEntryNo := GetClosedByEntryNo(VendorLedgerEntry."Entry No.", VendorLedgerEntry.Open, VendorLedgerEntry."Closed by Entry No.");
                    end;
                end;
            pGLEntry."Source Type"::Customer:
                if CustLedgerEntry.Get(pGLEntry."Entry No.") then begin
                    ExternalDocumentNo := CustLedgerEntry."External Document No.";
                    ClosedByEntryNo := CustLedgerEntry."Closed by Entry No.";
                    ClosedByEntryNo := GetClosedByEntryNo(CustLedgerEntry."Entry No.", CustLedgerEntry.Open, CustLedgerEntry."Closed by Entry No.");
                end;
            pGLEntry."Source Type"::Employee:
                if EmployeeLedgerEntry.Get(pGLEntry."Entry No.") then begin
                    ClosedByEntryNo := EmployeeLedgerEntry."Closed by Entry No.";
                    ClosedByEntryNo := GetClosedByEntryNo(EmployeeLedgerEntry."Entry No.", EmployeeLedgerEntry.Open, EmployeeLedgerEntry."Closed by Entry No.");
                end;
        end;
        pText := AppendColumns(ExternalDocumentNo, ClosedByEntryNo, pGLEntry."Dimension Set ID");
    end;

    local procedure AppendColumns(pExternalDocumentNo: Code[35]; pClosedByEntryNo: Integer; pDimensionSetId: Integer): Text
    begin
        exit('|' + pExternalDocumentNo
            + '|' + format(pClosedByEntryNo)
            //       '|' +// format(pDimensionSetID)
            + '|' + Dimensions(/*pGLEntry."Source Type", */pDimensionSetID));
    end;

    local procedure GetClosedByEntryNo(pEntryNo: Integer; pOpen: Boolean; pClosedByEntryNo: Integer): Integer
    begin
        if pClosedByEntryNo <> 0 then
            exit(pClosedByEntryNo)
        else
            if not pOpen then
                exit(pEntryNo);
    end;

    local procedure Dimensions(/*pSourceType: Enum "Gen. Journal Source Type";*/ pDimensionSetId: Integer) ReturnValue: Text
    var
        i: Integer;
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // if (pDimensionSetId = 0) or (pSourceType <> pSourceType::" ") then
        //     exit('||||||');
        for i := 1 to 8 do begin
            ReturnValue += '|';
            if ShortcutDimCode[i] <> '' then
                if DimensionSetEntry.Get(pDimensionSetId, ShortcutDimCode[i]) then
                    ReturnValue += DimensionSetEntry."Dimension Value Code";
        end;
    end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"WanaStart Import FR", OnAfterImportCell, '', false, false)]
    // local procedure OnAfterImportCell(var ImportLine: Record "WanaStart Import FR Line"; var CsvBuffer: Record "CSV Buffer")
    // begin
    //     case CsvBuffer."Field No." of
    //         19:
    //             ImportLine."_External Document No." := CopyStr(CsvBuffer.Value, 1, MaxStrLen(ImportLine."_External Document No."));
    //         20:
    //             ImportLine."_Applies-to ID" := CopyStr(CsvBuffer.Value, 1, MaxStrLen(ImportLine."_Applies-to ID"));
    //         21:
    //             ImportLine."_Shortcut Dimension 1 Code" := CsvBuffer.Value;
    //         22:
    //             ImportLine."_Shortcut Dimension 2 Code" := CsvBuffer.Value;
    //     end;
    // end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"WanaStart Import FR", OnBeforeInsert, '', false, false)]
    // local procedure OnBeforeInsert(var ImportLine: Record "WanaStart Import FR Line")
    // begin
    // end;
}
#endif
