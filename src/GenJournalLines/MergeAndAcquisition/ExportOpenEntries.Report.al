// Copy from report 10885 "Export G/L Entries - Tax Audit"
// + DocumentNoPrefix 
// + columns "External Document No.", "Closed by Entry No." for Vendor & Customer Ledger Entries
// + columns Dimension[1..8] for G/L entries
// - UsageCategory (must be run by URL Report ID)
// - FeatureTelemetry
// - Obsolete & if not CLEAN23

// namespace Microsoft.Finance.AuditFileExport;
namespace Wanamics.WanaStart;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Purchases.Payables;
using Microsoft.EServices.EDocument;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Reflection;
using System.Utilities;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;

report 87132 "WanaStart Open Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Export Open Entries';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    // DataAccessIntent = ReadOnly; Insert GenJournalLine

    dataset
    {
        dataitem(CustLedgerEntry; "Cust. Ledger Entry")
        {
            RequestFilterFields = "Customer No.";
            DataItemTableView = sorting("Customer No.", Open) where(Open = const(true));
            trigger OnPreDataItem()
            begin
                CustLedgerEntry.SetLoadFields("Customer No.", "Customer Name", "Transaction No.", "Posting Date", "Document Type", "Document No.", "Customer Posting Group", Description, "Transaction No.", "Debit Amount (LCY)", "Credit Amount (LCY)", "Currency Code", "Amount (LCY)");
            end;

            trigger OnAfterGetRecord()
            begin
                if CustLedgerEntry."Customer Posting Group" <> CustomerPostingGroup.Code then begin
                    CustomerPostingGroup.Get(CustLedgerEntry."Customer Posting Group");
                    if CustomerPostingGroup."Receivables Account" <> GLAccount."No." then
                        GLAccount.Get(CustomerPostingGroup."Receivables Account");
                end;
                AddCustomerLedgerEntry(CustLedgerEntry);
            end;
        }
        dataitem(VendorLedgerEntry; "Vendor Ledger Entry")
        {
            RequestFilterFields = "Vendor No.";
            DataItemTableView = sorting("Vendor No.", Open) where(Open = const(true));

            trigger OnPreDataItem()
            begin
                VendorLedgerEntry.SetLoadFields("Vendor No.", "Vendor Name", "Transaction No.", "Posting Date", "Document Type", "Document No.", "Vendor Posting Group", Description, "Transaction No.", "Debit Amount (LCY)", "Credit Amount (LCY)", "Currency Code", "Amount (LCY)");
            end;

            trigger OnAfterGetRecord()
            begin
                if VendorLedgerEntry."Vendor Posting Group" <> VendorPostingGroup.Code then begin
                    VendorPostingGroup.Get(VendorLedgerEntry."Vendor Posting Group");
                    if VendorPostingGroup."Payables Account" <> GLAccount."No." then
                        GLAccount.Get(VendorPostingGroup."Payables Account");
                end;
                AddVendorLedgerEntry(VendorLedgerEntry);
            end;
        }
        dataitem(BankAccount; "Bank Account")
        {
            DataItemTableView = sorting("No.");
            trigger OnPreDataItem()
            begin
                if BankAccountLedgerEntry.GetFilter("Bank Account No.") <> '' then
                    BankAccount.SetFilter("No.", BankAccountLedgerEntry.GetFilter("Bank Account No."));
            end;

            trigger OnAfterGetRecord()
            var
                ClosedBankAccLedgerEntry: Record "Bank Account Ledger Entry";
            begin
                if "Bank Acc. Posting Group" <> BankAccountPostingGroup.Code then begin
                    BankAccountPostingGroup.Get("Bank Acc. Posting Group");
                    if BankAccountPostingGroup."G/L Account No." <> GLAccount."No." then
                        GLAccount.Get(BankAccountPostingGroup."G/L Account No.");
                end;

                ClosedBankAccLedgerEntry.SetLoadFields("Bank Account No.", Open, Amount);
                ClosedBankAccLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
                ClosedBankAccLedgerEntry.SetRange(Open, false);
                ClosedBankAccLedgerEntry.CalcSums(Amount);

                ClosedBankAccLedgerEntry."Posting Date" := OpeningDate;
                ClosedBankAccLedgerEntry."Document No." := OpeningDocumentNo;
                ClosedBankAccLedgerEntry."Bank Account No." := "No.";
                ClosedBankAccLedgerEntry.Description := 'Posted Reconciliation';
                if ClosedBankAccLedgerEntry.Amount > 0 then
                    ClosedBankAccLedgerEntry."Debit Amount" := ClosedBankAccLedgerEntry."Amount"
                else
                    ClosedBankAccLedgerEntry."Credit Amount" := -ClosedBankAccLedgerEntry."Amount";
                AddBankAccountLedgerEntry(ClosedBankAccLedgerEntry);
            end;
        }
        dataitem(BankAccountLedgerEntry; "Bank Account Ledger Entry")
        {
            RequestFilterFields = "Bank Account No.";
            DataItemTableView = sorting("Bank Account No.", Open) where(Open = const(true));

            trigger OnPreDataItem()
            begin
                BankAccountLedgerEntry.SetLoadFields("Bank Account No.", "Transaction No.", "Posting Date", "Document Type", "Document No.", "Bank Acc. Posting Group", Description, "Transaction No.", "Debit Amount (LCY)", "Credit Amount (LCY)", "Currency Code", Amount);
            end;

            trigger OnAfterGetRecord()
            begin
                if "Bank Acc. Posting Group" <> BankAccountPostingGroup.Code then begin
                    BankAccountPostingGroup.Get("Bank Acc. Posting Group");
                    if BankAccountPostingGroup."G/L Account No." <> GLAccount."No." then
                        GLAccount.Get(BankAccountPostingGroup."G/L Account No.");
                end;
                AddBankAccountLedgerEntry(BankAccountLedgerEntry);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(OpeningDate; OpeningDate)
                    {
                        Caption = 'Opening Date';
                    }
                    field(OpeningDocumentNo; OpeningDocumentNo)
                    {
                        Caption = 'Opening DocumentNo';
                    }
                    field(JournalTemplateName; GenJournalLine."Journal Template Name")
                    {
                        Caption = 'Journal Template Name';
                        TableRelation = "Gen. Journal Template" where(Type = const(General), Recurring = const(false));
                        trigger OnValidate()
                        begin
                            GenJournalLine."Journal Batch Name" := '';
                        end;
                    }
                    field(JournalBatchName; GenJournalLine."Journal Batch Name")
                    {
                        Caption = 'Journal Batch Name"';
                        TableRelation = "Gen. Journal Batch".Name;
                        trigger OnLookup(var Text: Text): Boolean
                        var
                            GenJournalBatch: Record "Gen. Journal Batch";
                        begin
                            GenJournalLine.TestField("Journal Template Name");
                            GenJournalBatch.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
                            if Page.Runmodal(0, GenJournalBatch) = Action::LookupOK then
                                GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
                        end;
                    }
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        Tab[1] := 9;
        CRLF := TypeHelper.CRLFSeparator();

        if GenJournalLine."Journal Batch Name" = '' then begin
            TempBlob.CreateOutStream(OutStreamObj);
            WriteHeader();
        end else begin
            GenJournalLine.TestField("Journal Batch Name");
            GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
            GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
            if not GenJournalLine.IsEmpty() then
                GenJournalLine.FieldError("Journal Batch Name", 'must be empty');
        end;
    end;

    trigger OnPostReport()
    begin
        if GenJournalLine."Journal Batch Name" = '' then begin
            ToFileName := GetFileName();
            TempBlob.CreateInStream(InStreamObj);
            DownloadFromStream(InStreamObj, '', '', '', ToFileName);
        end;
    end;

    var
        TempBlob: Codeunit "Temp Blob";
        TypeHelper: Codeunit "Type Helper";
        InStreamObj: InStream;
        OutStreamObj: OutStream;
        CRLF: Text[2];
        ToFileName: Text[250];
        ToFileFullName: Text[250];
        Tab: Text[1];
        GLAccount: Record "G/L Account";
        OpeningDate: Date;
        OpeningDocumentNo: Code[20];
        GenJournalLine: Record "Gen. Journal Line";
        CustomerPostingGroup: Record "Customer Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
        BankAccountPostingGroup: Record "Bank Account Posting Group";

    local procedure GetFileName(): Text[250]
    var
        CompanyInformation: Record "Company Information";
        FileName: Text[250];
        InvalidWindowsChrStringTxt: Label '""#%&*:<>?\/{|}~';
    begin
        CompanyInformation.Get();
        CompanyInformation.TestField("Registration No.");
        FileName := Format(CompanyInformation.GetSIREN()) + '.txt';
        exit(DelChr(FileName, '=', InvalidWindowsChrStringTxt));
    end;

    local procedure WriteHeader()
    begin
        OutStreamObj.WriteText(
            'JournalCode' + Tab + 'JournalLib' + Tab + 'EcritureNum' + Tab + 'EcritureDate' + Tab + 'CompteNum' + Tab + 'CompteLib' + Tab + 'CompAuxNum' + Tab + 'CompAuxLib' + Tab + 'PieceRef' + Tab + '' +
            'PieceDate' + Tab + 'EcritureLib' + Tab + 'Debit' + Tab + 'Credit' + Tab + 'EcritureLet' + Tab + 'DateLet' + Tab + 'ValidDate' + Tab + 'Montantdevise' + Tab + 'Idevise' +
            AppendHeaders() + CRLF);
    end;

    local procedure ToString(pDate: Date): Text
    begin
        if pDate <> 0D then
            exit(Format(pDate, 8, '<Year4><Month,2><Day,2>'));
    end;

    local procedure ToString(pDecimal: Decimal): Text
    begin
        if pDecimal <> 0 then
            exit(Format(pDecimal, 0, '<Precision,2:2><Sign><Integer><Decimals><comma,,>'));
    end;

    local procedure AppendHeaders() ReturnValue: Text
    begin
        OnAppendHeaders(ReturnValue);
    end;

    // local procedure AppendColumns(pEntry: Record "Cust. Ledger Entry") ReturnValue: Text
    // begin
    //     OnAppendColumnsCust(pEntry, ReturnValue);
    // end;

    // local procedure AppendColumns(pEntry: Record "Vendor Ledger Entry") ReturnValue: Text
    // begin
    //     OnAppendColumnsVend(pEntry, ReturnValue);
    // end;

    // local procedure AppendColumns(pEntry: Record "Bank Account Ledger Entry") ReturnValue: Text
    // begin
    //     OnAppendColumnsBank(pEntry, ReturnValue);
    // end;

    local procedure AppendColumns(pGenJournalLine: Record "Gen. Journal Line") ReturnValue: Text
    begin
        OnAppendColumns(pGenJournalLine, ReturnValue);
    end;

    var
        ShortcutDimCode: array[8] of Code[20];
    // [IntegrationEvent(false, false)]
    // local procedure OnAfterSetLoadFields(
    //     var CustLedgerEntry: Record "Cust. Ledger Entry";
    //     var VendorLedgerEntry: Record "Vendor Ledger Entry";
    //     var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    // var
    //     GLSetup: Record "General Ledger Setup";
    //     DimMgt: Codeunit DimensionManagement;
    // begin
    //     GLSetup.Get();
    //     DimMgt.GetGLSetup(ShortcutDimCode);
    //     //???? CustLedgerEntry.AddLoadFields(); ????
    //     //????VendorLedgerEntry.AddLoadFields("Pdf Path");????
    //     //????BankLedgerEntry.AddLoadFields(); ????
    // end;

    // [IntegrationEvent(false, false)]
    local procedure OnAppendHeaders(var pText: Text)
    var
        i: Integer;
    begin
        pText := Tab + 'ExternalDocumentNo' + Tab + 'ClosedByEntryNo';
        for i := 1 to 8 do
            pText += Tab + ShortcutDimCode[i];
        pText += Tab + 'IncomingDocumentNo';
    end;

    // // [IntegrationEvent(false, false)]
    // local procedure OnAppendColumnsCust(pEntry: Record "Cust. Ledger Entry"; var pText: Text);
    // begin
    //     pText := AppendColumns(pEntry."External Document No.", 0, pEntry."Dimension Set ID", 0);
    // end;

    // // [IntegrationEvent(false, false)]
    // local procedure OnAppendColumnsVend(pEntry: Record "Vendor Ledger Entry"; var pText: Text);
    // begin
    //     pText := AppendColumns(pEntry."External Document No.", 0, pEntry."Dimension Set ID", GetIncomingDocumentNo(pEntry));
    // end;

    // // [IntegrationEvent(false, false)]
    // local procedure OnAppendColumnsBank(pEntry: Record "Bank Account Ledger Entry"; var pText: Text);
    // begin
    //     pText := AppendColumns(pEntry."External Document No.", 0, pEntry."Dimension Set ID", 0);
    // end;

    // [IntegrationEvent(false, false)]
    local procedure OnAppendColumns(pGenJournalLine: Record "Gen. Journal Line"; var pText: Text);
    begin
        pText :=
            Tab + pGenJournalLine."External Document No."
            // + Tab + format(pClosedByEntryNo)
            // Tab +// format(pDimensionSetID)
            + Tab + Dimensions(pGenJournalLine."Dimension Set ID")
            + Tab + format(pGenJournalLine."Incoming Document Entry No.");
    end;

    local procedure Dimensions(pDimensionSetId: Integer) ReturnValue: Text
    var
        i: Integer;
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        for i := 1 to 8 do begin
            ReturnValue += Tab;
            if (pDimensionSetId <> 0) and (ShortcutDimCode[i] <> '') then
                if DimensionSetEntry.Get(pDimensionSetId, ShortcutDimCode[i]) then
                    ReturnValue += DimensionSetEntry."Dimension Value Code";
        end;
    end;

    local procedure GetIncomingDocumentNo(pEntry: Record "Vendor Ledger Entry"): Integer
    begin
        // if pEntry."Pdf Path" <> '' then
        // ...
        // exit(??)
    end;

    local procedure AddCustomerLedgerEntry(var pLedgerEntry: Record "Cust. Ledger Entry")
    begin
        GenJournalLine."Posting Date" := pLedgerEntry."Posting Date";
        GenJournalLine."Account Type" := "Gen. Journal Account Type"::Customer;
        GenJournalLine."Account No." := pLedgerEntry."Customer No.";
        GenJournalLine."Document No." := pLedgerEntry."Document No.";
        GenJournalLine."Document Date" := pLedgerEntry."Document Date";
        GenJournalLine."Due Date" := pLedgerEntry."Due Date";
        GenJournalLine.Description := pLedgerEntry.Description;
        GenJournalLine."Currency Code" := pLedgerEntry."Currency Code";
        GenJournalLine.Validate(Amount, pLedgerEntry.Amount);
        // GenJournalLine."Amount (LCY)" := pLedgerEntry."Amount (LCY)";
        // GenJournalLine."Currency Factor" := pLedgerEntry.Amount / pLedgerEntry."Amount (LCY)";
        GenJournalLine."External Document No." := pLedgerEntry."External Document No.";
        GenJournalLine."Dimension Set ID" := pLedgerEntry."Dimension Set ID";
        GenJournalLine."Incoming Document Entry No." := GetIncomingDocumentNo(GenJournalLine);
        AddLine(GenJournalLine, pLedgerEntry."Customer Name");
    end;

    local procedure AddVendorLedgerEntry(var pLedgerEntry: Record "Vendor Ledger Entry")
    begin
        GenJournalLine."Line No." += 1;
        GenJournalLine."Posting Date" := pLedgerEntry."Posting Date";
        GenJournalLine."Account Type" := "Gen. Journal Account Type"::Vendor;
        GenJournalLine."Account No." := pLedgerEntry."Vendor No.";
        GenJournalLine."Document No." := pLedgerEntry."Document No.";
        GenJournalLine."Document Date" := pLedgerEntry."Document Date";
        GenJournalLine."Due Date" := pLedgerEntry."Due Date";
        GenJournalLine.Description := pLedgerEntry.Description;
        GenJournalLine."Currency Code" := pLedgerEntry."Currency Code";
        GenJournalLine.Validate(Amount, pLedgerEntry.Amount);
        // GenJournalLine."Amount (LCY)" := pLedgerEntry."Amount (LCY)";
        // GenJournalLine."Currency Factor" := pLedgerEntry.Amount / pLedgerEntry."Amount (LCY)";
        GenJournalLine."External Document No." := pLedgerEntry."External Document No.";
        GenJournalLine."Dimension Set ID" := pLedgerEntry."Dimension Set ID";
        GenJournalLine."Incoming Document Entry No." := GetIncomingDocumentNo(GenJournalLine);
        AddLine(GenJournalLine, pLedgerEntry."Vendor Name");
    end;

    local procedure AddBankAccountLedgerEntry(var pBankAccountLedgerEntry: Record "Bank Account Ledger Entry");
    begin
        GenJournalLine."Posting Date" := pBankAccountLedgerEntry."Posting Date";
        GenJournalLine."Document Date" := pBankAccountLedgerEntry."Document Date";
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"Bank Account";
        GenJournalLine."Account No." := pBankAccountLedgerEntry."Bank Account No.";
        GenJournalLine."Document No." := pBankAccountLedgerEntry."Document No.";
        GenJournalLine.Description := pBankAccountLedgerEntry.Description;
        GenJournalLine.Validate(Amount, pBankAccountLedgerEntry.Amount);
        GenJournalLine."External Document No." := pBankAccountLedgerEntry."External Document No.";
        GenJournalLine."Dimension Set ID" := pBankAccountLedgerEntry."Dimension Set ID";
        GenJournalLine."Incoming Document Entry No." := GetIncomingDocumentNo(GenJournalLine);
        AddLine(GenJournalLine, BankAccount.Name)
    end;

    local procedure GetIncomingDocumentNo(var pGenJournalLine: Record "Gen. Journal Line"): Integer
    var
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument.SetCurrentKey("Document No.", "Posting Date");
        IncomingDocument.SetRange("Document No.", pGenJournalLine."Document No.");
        IncomingDocument.SetRange("Posting Date", pGenJournalLine."Posting Date");
        if IncomingDocument.FindFirst() then
            exit(IncomingDocument."Entry No.");
    end;

    local procedure AddLine(var pGenJournalLine: Record "Gen. Journal Line"; pName: Text)
    begin
        if pGenJournalLine.Amount = 0 then
            exit;
        if GenJournalLine."Journal Batch Name" = '' then
            WriteText(GenJournalLine, pName)
        else begin
            GenJournalLine."Line No." += 1;
            GenJournalLine.Insert();
        end;
    end;

    local procedure WriteText(var pGenJournalLine: Record "Gen. Journal Line"; pName: Text)
    begin
        OutStreamObj.WriteText(
            '' // JournalCode
            + Tab // JournalLib
            + Tab + '0' // EcritureNum
            + Tab + ToString(pGenJournalLine."Posting Date") // EcritureDate
            + Tab + GLAccount."No." // CompteNum
            + Tab + GLAccount.Name // CompteLib
            + Tab + pGenJournalLine."Account No." // CompAuxNum
            + Tab + pName // CompAuxLib
            + Tab + pGenJournalLine."Document No." // PieceRef
            + Tab + ToString(pGenJournalLine."Document Date") // PieceDate
            + Tab + pGenJournalLine.Description // EcritureLib
            + Tab + ToString(pGenJournalLine."Debit Amount") // Debit
            + Tab + ToString(pGenJournalLine."Credit Amount") // Credit
            + Tab // EcritureLet
            + Tab // DateLet
            + Tab // ValidDate
            + Tab + ToString(pGenJournalLine.Amount) // Montantdevise
            + Tab + pGenJournalLine."Currency Code" // Idevise
            + AppendColumns(pGenJournalLine)
            + CRLF);
    end;
}
