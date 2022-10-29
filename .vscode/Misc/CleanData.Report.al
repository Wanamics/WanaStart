report 81911 "wanaStart Clean Data"
{
    Caption = 'Clean Data';
    ProcessingOnly = true;
    Permissions =
        tabledata "G/L Entry" = MD, // 15
        tabledata "Cust. Ledger Entry" = MD, // 21
        tabledata "Vendor Ledger Entry" = MD, // 25
        tabledata "Item Ledger Entry" = MD, // 32
        tabledata "G/L Register" = MD, // 45
        tabledata "Item Register" = MD, // 46
        tabledata "Exch. Rate Adjmt. Reg." = MD, // 86
        tabledata "Date Compr. Register" = MD, // 87
        tabledata "G/L Budget Entry" = MD, // 96
        tabledata "Sales Shipment Header" = M, // 110
        tabledata "Sales Shipment Line" = M, // 111
        tabledata "Sales Invoice Header" = M, // 112
        tabledata "Sales Cr.Memo Header" = M, // 114
        tabledata "Purch. Rcpt. Header" = M, // 120
        tabledata "Purch. Rcpt. Line" = M, // 121
        tabledata "Purch. Inv. Header" = M, // 122
        tabledata "Purch. Cr. Memo Hdr." = M, // 124
        tabledata "Job Ledger Entry" = MD, // 169
        tabledata "Posted Gen. Journal Line" = D, // 181
        tabledata "Posted Gen. Journal Batch" = D, // 182
        tabledata "Res. Ledger Entry" = MD, // 203
        tabledata "Resource Register" = MD, // 240
        tabledata "Job Register" = MD, // 241
        tabledata "G/L Entry - VAT Entry Link" = MD, // 253
        tabledata "VAT Entry" = MD, // 254
        tabledata "Bank Account Ledger Entry" = MD, // 271
        tabledata "Check Ledger Entry" = MD, // 272
        tabledata "Bank Account Statement" = MD, // 275
        tabledata "Bank Account Statement Line" = MD, // 276
        tabledata "Phys. Inventory Ledger Entry" = MD, // 281
        tabledata "Reservation Entry" = MD, // 337
        tabledata "Item Application Entry" = MD, // 339
        tabledata "Item Application Entry History" = MD, // 343
        tabledata "Analysis View Entry" = MD, // 365
        tabledata "Analysis View Budget Entry" = MD, // 366
        tabledata "G/L Account (Analysis View)" = MD, // 376
        tabledata "Detailed Cust. Ledg. Entry" = MD, // 379
        tabledata "Detailed Vendor Ledg. Entry" = MD, // 380
        tabledata "Change Log Entry" = MD, // 405
        tabledata "Posted Approval Entry" = MD, // 456
        tabledata "Posted Approval Comment Line" = MD, // 457
        tabledata "Overdue Approval Entry" = MD, // 458
        tabledata "Dimension Set Entry" = MD, //480
        tabledata "Dimension Set Tree Node" = MD, //481
        tabledata "Job WIP Entry" = MD, // 1004
        tabledata "Job WIP G/L Entry" = MD, // 1005
        tabledata "Job WIP Warning" = MD, // 1007
        tabledata "Job Entry No." = MD, // 1015
        tabledata "Job WIP Total" = MD, // 1021
        tabledata "Credit Transfer Register" = D, // 1205
        tabledata "Credit Transfer Entry" = D, // 1206
        tabledata "Posted Payment Recon. Hdr" = D, // 1295
        tabledata "Posted Payment Recon. Line" = D, // 1296
        tabledata "Interaction Log Entry" = MD, // 5065
        tabledata "To-do" = MD, // 5080
        tabledata "Employee Absence" = MD, // 5207
        tabledata "Employee Ledger Entry" = MD, // 5222
        tabledata "Detailed Employee Ledger Entry" = MD, // 5223
        tabledata "FA Ledger Entry" = MD, // 5601
        tabledata "FA Register" = MD, // 5617
        tabledata "Maintenance Ledger Entry" = MD, // 5625
        tabledata "Value Entry" = MD, // 5802
        tabledata "Avg. Cost Adjmt. Entry Point" = MD, // 5804
        tabledata "Rounding Residual Buffer" = MD, // 5810
        tabledata "Post Value Entry to G/L" = MD, // 5811
        tabledata "G/L - Item Ledger Relation" = MD, // 5823
        tabledata "Capacity Ledger Entry" = MD, // 5832
        tabledata "Inventory Adjmt. Entry (Order)" = D, // 5896
        tabledata "Service Ledger Entry" = MD, // 5907
        tabledata "Warranty Ledger Entry" = MD, // 5908
        tabledata "Service Register" = MD, // 5934
        tabledata "Service Document Register" = MD, // 5936
        tabledata "Warehouse Entry" = MD, // 7312
        tabledata "Warehouse Register" = D, // 7313
        tabledata "Shipment Invoiced" = D, // 10825
        tabledata "Planning Assignment" = D; // 99000850
    requestpage
    {
        SaveValues = true;
        layout
        {
            area(content)
            {
                field(CleanSetup; CleanOption[TableType::Setup])
                {
                    ApplicationArea = All;
                    Caption = 'Setup';
                }
                field(CleanMaster; CleanOption[TableType::Master])
                {
                    ApplicationArea = All;
                    Caption = 'Masterdata';
                }
                field(CleanJournal; CleanOption[TableType::Journal])
                {
                    ApplicationArea = All;
                    Caption = 'Journals';
                }
                field(CleanEntry; CleanOption[TableType::Entry])
                {
                    ApplicationArea = All;
                    Caption = 'Entries';
                }
                field(CleanDocuments; CleanOption[TableType::Document])
                {
                    ApplicationArea = All;
                    Caption = 'Documents';
                }
                field(CleanArchive; CleanOption[TableType::Archive])
                {
                    ApplicationArea = All;
                    Caption = 'Archives';
                }
                field(CleanPosted; CleanOption[TableType::Posted])
                {
                    ApplicationArea = All;
                    Caption = 'Posted documents';
                }
                field(CleanJob; CleanOption[TableType::Job])
                {
                    ApplicationArea = All;
                    Caption = 'Jobs';
                }
                field(CleanBuffer; CleanOption[TableType::Buffer])
                {
                    ApplicationArea = All;
                    Caption = 'Buffer';
                }
            }
        }
        actions
        {
            area(processing)
            {
            }
        }
        trigger OnOpenPage()
        var
            AccessControl: Record "Access Control";
            tMustBeSuperUser: Label 'You must be SUPER user';
        begin
            if not AccessControl.Get(UserSecurityId(), 'SUPER', '') then
                Error(tMustBeSuperUser);
        end;
    }
    var
        TableType: Option " ",Setup,Master,Journal,Entry,Document,Archive,Posted,Job,Buffer;
        CleanOption: array[10] of boolean;
        ProgressDialog: Dialog;
        ProgressCount: Integer;
        ProgressMax: Integer;
        gClean: Boolean;

    trigger OnPreReport()
    var
        tConfirm: Label 'Do you want to DELETE ALL LIVE DATA for company %1?';
        tAreYouSure: Label 'Are you sure (WARNING : this operation can not be canceled)?';
    begin
        if not Confirm(tConfirm, false, CompanyName) then
            exit;
        if not Confirm(tAreYouSure, false) then
            exit;

        for TableType := TableType::Setup to TableType::Buffer do
            if CleanOption[TableType] then
                CleanTableType(TableType);
    end;

    procedure CleanTableType(pTableType: Integer)
    var
        ltProgress: Label 'Current process @1@@@@@@@@@@@@@@@\';
        ltTable: Label 'Current status  #2###################';
        SalesSetup: Record "Sales & Receivables Setup";
        SalesSetupAllowDocumentDeletionBefore: Date;
        PurchSetup: Record "Purchases & Payables Setup";
        PurchSetupAllowDocumentDeletionBefore: Date;
    begin
        TableType := pTableType;
        if TableType = TableType::Posted then begin
            SalesSetup.Get();
            SalesSetupAllowDocumentDeletionBefore := SalesSetup."Allow Document Deletion Before";
            SalesSetup."Allow Document Deletion Before" := 99991231D;
            SalesSetup.Modify();
            PurchSetup.Get();
            PurchSetupAllowDocumentDeletionBefore := PurchSetup."Allow Document Deletion Before";
            PurchSetup."Allow Document Deletion Before" := 99991231D;
            PurchSetup.Modify();
        end;

        ProgressMax := 0;
        ProgressCount := 0;
        ProgressDialog.Open(ltProgress + ltTable);
        FOR gClean := false TO true DO
            DoCleaning;
        ProgressDialog.CLOSE();

        if TableType = TableType::Posted then begin
            SalesSetup.Get();
            SalesSetup."Allow Document Deletion Before" := SalesSetupAllowDocumentDeletionBefore;
            SalesSetup.Modify();
            PurchSetup.Get();
            PurchSetup."Allow Document Deletion Before" := PurchSetupAllowDocumentDeletionBefore;
            PurchSetup.Modify();
        end;

        Commit();
    end;

    local procedure CleanTable(pTableNo: Integer; pTableType: Integer; pTrigger: Boolean)
    var
        lRecordRef: RecordRef;
        ChangeLogEntry: Record "Change Log Entry";
        Handled: Boolean;
    begin
        if pTableType <> TableType then
            exit
        else
            if not gClean then
                ProgressMax += 1
            else begin
                lRecordRef.Open(pTableNo);
                ProgressDialog.Update(2, Format(pTableNo) + ' : ' + lRecordRef.Caption);
                ProgressCount += 1;
                ProgressDialog.Update(1, Round(ProgressCount / ProgressMax * 10000, 1));
                SetTableFilters(lRecordRef);
                ModifyToDelete(pTableNo);
                lRecordRef.DeleteAll(pTrigger);
                ChangeLogEntry.SetCurrentKey("Table No.");
                ChangeLogEntry.SetRange("Table No.", lRecordRef.Number);
                ChangeLogEntry.DeleteAll(true);
            end;
    end;

    local procedure DoCleaning()
    begin
        CleanTable(Database::"Applied Payment Entry", TableType::Entry, true); // 1294 // Before Customer/Vendor/Enmployee Ledger Entry
        CleanTable(Database::"Bank Acc. Reconciliation", TableType::Document, true); // 273 
        CleanTable(Database::"Salesperson/Purchaser", TableType::Master, true); // 13
        CleanTable(Database::"G/L Entry", TableType::Entry, true); // 17
        CleanTable(Database::Customer, TableType::Master, true); // 18
        CleanTable(Database::"Cust. Ledger Entry", TableType::Entry, true); // 21
        CleanTable(Database::Vendor, TableType::Master, true); // 23
        CleanTable(Database::"Vendor Ledger Entry", TableType::Entry, true); // 25
        CleanTable(Database::Item, TableType::Master, true); // 27
        CleanTable(Database::"Item Ledger Entry", TableType::Entry, true); // 32
        CleanTable(Database::"Sales Header", TableType::Document, false); // 36
        CleanTable(Database::"Sales Line", TableType::Document, false); // 37
        CleanTable(Database::"Purchase Header", TableType::Document, false); // 38
        CleanTable(Database::"Purchase Line", TableType::Document, false); // 39
        CleanTable(Database::"Purch. Comment Line", TableType::Document, true); // 43
        CleanTable(Database::"Sales Comment Line", TableType::Document, true); // 44
        CleanTable(Database::"G/L Register", TableType::Entry, true); // 45
        CleanTable(Database::"Item Register", TableType::Entry, true); // 46
        CleanTable(Database::"Gen. Journal Line", TableType::Journal, true); // 81
        CleanTable(Database::"Item Journal Line", TableType::Journal, true); // 83
        CleanTable(Database::"Exch. Rate Adjmt. Reg.", TableType::Entry, true); // 86
        CleanTable(Database::"Date Compr. Register", TableType::Entry, true); // 87
        CleanTable(Database::"BOM Component", TableType::Master, true); // 90
        CleanTable(Database::"G/L Budget Name", TableType::Setup, true); // 95
        CleanTable(Database::"G/L Budget Entry", TableType::Entry, true); // 96
        CleanTable(Database::"Sales Shipment Header", TableType::Posted, true); // 110
        CleanTable(Database::"Sales Shipment Line", TableType::Posted, true); // 111
        CleanTable(Database::"Sales Invoice Header", TableType::Posted, true); // 112
        CleanTable(Database::"Sales Invoice Line", TableType::Posted, true); // 113
        CleanTable(Database::"Sales Cr.Memo Header", TableType::Posted, true); // 114
        CleanTable(Database::"Sales Cr.Memo Line", TableType::Posted, true); // 115
        CleanTable(Database::"Purch. Rcpt. Header", TableType::Posted, true); // 120
        CleanTable(Database::"Purch. Rcpt. Line", TableType::Posted, true); // 121
        CleanTable(Database::"Purch. Inv. Header", TableType::Posted, true); // 122
        CleanTable(Database::"Purch. Inv. Line", TableType::Posted, true); // 123
        CleanTable(Database::"Purch. Cr. Memo Hdr.", TableType::Posted, true); // 124
        CleanTable(Database::"Purch. Cr. Memo Line", TableType::Posted, true); // 125
        CleanTable(Database::"Resource Group", TableType::Master, true); // 152
        CleanTable(Database::Resource, TableType::Master, true); // 156
        CleanTable(Database::Job, TableType::Job, true); // 167
        CleanTable(Database::"Job Ledger Entry", TableType::Entry, true); // 169
        CleanTable(Database::"Posted Gen. Journal Line", TableType::Posted, true); // 181
        CleanTable(Database::"Posted Gen. Journal Batch", TableType::Posted, true); // 182
        CleanTable(Database::"Res. Ledger Entry", TableType::Entry, true); // 203
        CleanTable(Database::"Res. Journal Line", TableType::Journal, true); // 207
        CleanTable(Database::"Job Posting Group", TableType::Setup, true); // 208
        CleanTable(Database::"Job Journal Template", TableType::Setup, true); // 209
        CleanTable(Database::"Job Journal Line", TableType::Journal, true); // 210
        CleanTable(Database::"Job Posting Buffer", TableType::Buffer, true); // 212
        CleanTable(Database::"Job Journal Batch", TableType::Setup, true); // 237
        CleanTable(Database::"Resource Register", TableType::Entry, true); // 240
        CleanTable(Database::"Job Register", TableType::Entry, true); // 241
        CleanTable(Database::"Requisition Line", TableType::Journal, true); // 246
        CleanTable(Database::"G/L Entry - VAT Entry Link", TableType::Entry, true); // 253
        CleanTable(Database::"VAT Entry", TableType::Entry, true); // 254
        CleanTable(Database::"Intrastat Jnl. Line", TableType::Journal, true); // 263
        CleanTable(Database::"Bank Account", TableType::Master, true); // 270
        CleanTable(Database::"Bank Account Ledger Entry", TableType::Entry, true); // 271
        CleanTable(Database::"Check Ledger Entry", TableType::Entry, true); // 272
        CleanTable(Database::"Bank Acc. Reconciliation", TableType::Document, true); // 273
        CleanTable(Database::"Bank Account Statement", TableType::Posted, false); // 275
        CleanTable(Database::"Bank Account Statement Line", TableType::Posted, true); // 276
        CleanTable(Database::"Job Journal Quantity", TableType::Setup, true); // 278
        CleanTable(Database::"Phys. Inventory Ledger Entry", TableType::Entry, true); // 281
        CleanTable(Database::"Reminder Header", TableType::Document, true); // 295
        CleanTable(Database::"Issued Reminder Header", TableType::Posted, true); // 297
        CleanTable(Database::"Issued Reminder Line", TableType::Posted, true); // 298
        CleanTable(Database::"Reminder Comment Line", TableType::Document, true); // 299
        CleanTable(Database::"Reminder/Fin. Charge Entry", TableType::Posted, true); // 300
        CleanTable(Database::"Finance Charge Memo Header", TableType::Document, true); // 302
        CleanTable(Database::"Issued Fin. Charge Memo Header", TableType::Posted, true); // 304
        CleanTable(Database::"Issued Fin. Charge Memo Line", TableType::Posted, true); // 305
        CleanTable(Database::"Fin. Charge Comment Line", TableType::Document, true); // 306
        CleanTable(Database::"Reservation Entry", TableType::Entry, true); // 337
        CleanTable(Database::"Item Application Entry", TableType::Entry, true); // 339
        CleanTable(Database::"Item Application Entry History", TableType::Entry, true); // 343
        CleanTable(Database::"Analysis View Entry", TableType::Entry, true); // 365
        CleanTable(Database::"Analysis View Budget Entry", TableType::Entry, true); // 366
        CleanTable(Database::"G/L Account (Analysis View)", TableType::Entry, true); // 376
        CleanTable(Database::"Detailed Cust. Ledg. Entry", TableType::Entry, true); // 379
        CleanTable(Database::"Detailed Vendor Ledg. Entry", TableType::Entry, true); // 380
        CleanTable(Database::"Posted Approval Entry", TableType::Entry, true); // 456
        CleanTable(Database::"Posted Approval Comment Line", TableType::Entry, true); // 457
        CleanTable(Database::"Overdue Approval Entry", TableType::Entry, true); // 458
        CleanTable(Database::"Dimension Set Entry", TableType::Entry, true); // 480
        CleanTable(Database::"Dimension Set Tree Node", TableType::Entry, true); // 481
        CleanTable(Database::"Assembly Header", TableType::Document, true); // 900
        CleanTable(Database::"Posted Assembly Header", TableType::Posted, true); // 910
        CleanTable(Database::"Posted Assembly Line", TableType::Posted, true); // 911
        CleanTable(Database::"Job Task", TableType::Job, true); // 1001
        CleanTable(Database::"Job Task Dimension", TableType::Job, true); // 1002
        CleanTable(Database::"Job Planning Line", TableType::Job, true); // 1003
        CleanTable(Database::"Job WIP Entry", TableType::Entry, true); // 1004
        CleanTable(Database::"Job WIP G/L Entry", TableType::Entry, true); // 1005
        CleanTable(Database::"Job WIP Method", TableType::Setup, true); // 1006
        CleanTable(Database::"Job WIP Warning", TableType::Entry, true); // 1007
#if CLEAN
        CleanTable(Database::"Job Resource Price", TableType::Job, true); // 1012
        CleanTable(Database::"Job Item Price", TableType::Job, true); // 1013
        CleanTable(Database::"Job G/L Account Price", TableType::Job, true); // 1014
#ENDIF
        CleanTable(Database::"Job Entry No.", TableType::Entry, true); // 1015
        CleanTable(Database::"Job Buffer", TableType::Buffer, true); // 1017
        CleanTable(Database::"Job WIP Buffer", TableType::Buffer, true); // 1018
        CleanTable(Database::"Job Difference Buffer", TableType::Buffer, true); // 1019
        CleanTable(Database::"Job Usage Link", TableType::Job, true); // 1020
        CleanTable(Database::"Job WIP Total", TableType::Entry, true); // 1021
        CleanTable(Database::"Job Planning Line Invoice", TableType::Job, true); // 1022
        CleanTable(Database::"Credit Transfer Register", TableType::Entry, true); // 1205
        CleanTable(Database::"Credit Transfer Entry", TableType::Entry, true); // 1206
        CleanTable(Database::"Posted Payment Recon. Hdr", TableType::Entry, true); // 1295
        CleanTable(Database::"Posted Payment Recon. Line", TableType::Entry, true); // 1296
        CleanTable(Database::Contact, TableType::Master, true); // 5050
        CleanTable(Database::"Interaction Log Entry", TableType::Entry, true); // 5065
        CleanTable(Database::Campaign, TableType::Document, true); // 5071
        CleanTable(Database::"Campaign Entry", TableType::Document, true); // 5072
        CleanTable(Database::"Campaign Status", TableType::Document, true); // 5073
        CleanTable(Database::"Segment Header", TableType::Master, true); // 5076
        CleanTable(Database::"To-do", TableType::Entry, true); // 5080
        CleanTable(Database::Team, TableType::Master, true); // 5083
        CleanTable(Database::Opportunity, TableType::Document, true); // 5092
        CleanTable(Database::"Sales Header Archive", TableType::Archive, true); // 5107
        CleanTable(Database::"Sales Line Archive", TableType::Archive, true); // 5108
        CleanTable(Database::"Purchase Header Archive", TableType::Archive, true); // 5109
        CleanTable(Database::"Purchase Line Archive", TableType::Archive, true); // 5110
        CleanTable(Database::Employee, TableType::Master, true); // 5200
        CleanTable(Database::"Employee Absence", TableType::Entry, true); // 5207
        CleanTable(Database::"Employee Ledger Entry", TableType::Entry, true); // 5222
        CleanTable(Database::"Detailed Employee Ledger Entry", TableType::Entry, true); // 5223
        CleanTable(Database::"Production Order", TableType::Document, true); // 5405
        CleanTable(Database::"Fixed Asset", TableType::Master, true); // 5600
        CleanTable(Database::"FA Ledger Entry", TableType::Entry, true); // 5601
        CleanTable(Database::"FA Register", TableType::Entry, true); // 5617
        CleanTable(Database::"FA Journal Line", TableType::Journal, true); // 5621
        CleanTable(Database::"Maintenance Ledger Entry", TableType::Entry, true); // 5625
        CleanTable(Database::"Nonstock Item", TableType::Master, true); // 5718
        CleanTable(Database::"Item Category", TableType::Master, true); // 5722
        CleanTable(Database::"Transfer Header", TableType::Document, false); // 5740
        CleanTable(Database::"Transfer Line", TableType::Document, false); // 5741
        CleanTable(Database::"Transfer Shipment Header", TableType::Posted, true); // 5744
        CleanTable(Database::"Transfer Receipt Header", TableType::Posted, true); // 5746
        CleanTable(Database::"Warehouse Request", TableType::Document, true); // 5765
        CleanTable(Database::"Warehouse Activity Header", TableType::Document, true); // 5766
        CleanTable(Database::"Registered Whse. Activity Hdr.", TableType::Posted, true); // 5772
        CleanTable(Database::"Registered Whse. Activity Line", TableType::Posted, true); // 5773
        CleanTable(Database::"Value Entry", TableType::Entry, true); // 5802
        CleanTable(Database::"Avg. Cost Adjmt. Entry Point", TableType::Entry, true); // 5804
        CleanTable(Database::"Item Charge Assignment (Purch)", TableType::Document, true); // 5805
        CleanTable(Database::"Item Charge Assignment (Sales)", TableType::Document, true); // 5809
        CleanTable(Database::"Rounding Residual Buffer", TableType::Entry, true); // 5810
        CleanTable(Database::"Post Value Entry to G/L", TableType::Entry, true); // 5811
        CleanTable(Database::"G/L - Item Ledger Relation", TableType::Entry, true); // 5823
        CleanTable(Database::"Capacity Ledger Entry", TableType::Entry, true); // 5832
        CleanTable(Database::"Phys. Invt. Order Header", TableType::Document, true); // 5875
        CleanTable(Database::"Phys. Invt. Order Line", TableType::Document, true); // 5876
        CleanTable(Database::"Phys. Invt. Record Header", TableType::Document, true); // 5877
        CleanTable(Database::"Phys. Invt. Record Line", TableType::Document, true); // 5878
        CleanTable(Database::"Inventory Adjmt. Entry (Order)", TableType::Entry, true); // 5896
        CleanTable(Database::"Service Header", TableType::Document, true); // 5900
        CleanTable(Database::"Service Ledger Entry", TableType::Entry, true); // 5907
        CleanTable(Database::"Warranty Ledger Entry", TableType::Entry, true); // 5908
        CleanTable(Database::"Service Register", TableType::Entry, true); // 5934
        CleanTable(Database::"Service Document Register", TableType::Entry, true); // 5936
        CleanTable(Database::"Service Contract Header", TableType::Document, true); // 5965
        CleanTable(Database::"Contract Change Log", TableType::Document, true); // 5967
        CleanTable(Database::"Contract Gain/Loss Entry", TableType::Document, true); // 5969
        CleanTable(Database::"Filed Service Contract Header", TableType::Posted, true); // 5970
        CleanTable(Database::"Filed Contract Line", TableType::Entry, true); // 5971
        CleanTable(Database::"Return Shipment Header", TableType::Posted, true); // 6650
        CleanTable(Database::"Return Receipt Header", TableType::Posted, true); // 6660
        CleanTable(Database::"Warehouse Entry", TableType::Entry, true); // 7312
        CleanTable(Database::"Warehouse Register", TableType::Entry, true); // 7313
        CleanTable(Database::"Warehouse Receipt Header", TableType::Posted, true); // 7316
        CleanTable(Database::"Posted Whse. Receipt Header", TableType::Posted, true); // 7318
        CleanTable(Database::"Warehouse Shipment Header", TableType::Posted, true); // 7320
        CleanTable(Database::"Posted Whse. Shipment Header", TableType::Posted, true); // 7322
        CleanTable(Database::"Whse. Put-away Request", TableType::Document, true); // 7324
        CleanTable(Database::"Whse. Pick Request", TableType::Document, true); // 7325
        CleanTable(Database::"Shipment Invoiced", TableType::Posted, true); // 10825
        CleanTable(Database::"Production BOM Header", TableType::Master, true); // 99000771
        CleanTable(Database::"Planning Assignment", TableType::Entry, true); // 99000850
    end;

    local procedure ModifyToDelete(pTableID: Integer)
    var
        lRecordRef: RecordRef;
        NoSeriesLine: Record "No. Series Line";
        Item: Record "Item";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        GenJnlLine: Record "Gen. Journal Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchReceiptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        Job: Record "Job";
        AssembleToOrderLink: Record "Assemble-to-Order Link";
        Opportunity: Record Opportunity;
        FixedAsset: Record "Fixed Asset";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        case pTableID of
            Database::Customer: // 18
                ServiceItem.ModifyAll("Customer No.", ''); // 5940
            Database::Item: // 27
                begin
                    Item.ModifyAll("Production BOM No.", '');
                    ServiceItem.ModifyAll("Item No.", ''); // 5940
                    CleanTable(Database::"BOM Component", TableType::Master, true); // 90
                    CleanTable(Database::"Assembly Header", TableType::Master, true); // 900
                    CleanTable(Database::"Posted Assembly Header", TableType::Master, true); // 910
                    CleanTable(Database::"Production BOM Header", TableType::Master, true); // 99000771
                end;
            Database::"Item Ledger Entry": // 32
                begin
                    ItemLedgerEntry.SetFilter("Order No.", '<>%1', '');
                    ItemLedgerEntry.ModifyAll("Order No.", '');
                end;
            Database::"Purchase Line": // 39
                begin
                    PurchaseLine.SetFilter("Prod. Order No.", '<>%1', '');
                    PurchaseLine.ModifyAll("Prod. Order No.", '');
                end;
            Database::"Gen. Journal Line": // 81
                begin
                    GenJnlLine.SetRange("Check Printed", true);
                    GenJnlLine.ModifyAll("Check Printed", false);
                end;
            Database::"Sales Shipment Header": // 110
                begin
                    SalesShipmentHeader.SetRange("No. Printed", 0);
                    SalesShipmentHeader.ModifyAll("No. Printed", -1);
                    SalesShipmentLine.SetFilter(Quantity, '<>0');
                    if SalesShipmentLine.FindSet then
                        repeat
                            SalesShipmentLine."Quantity Invoiced" := SalesShipmentLine.Quantity;
                            SalesShipmentLine.Modify();
                        until SalesShipmentLine.Next() = 0;
                end;
            Database::"Sales Invoice Header": // 112
                begin
                    SalesInvoiceHeader.SetRange("No. Printed", 0);
                    SalesInvoiceHeader.ModifyAll("No. Printed", -1);
                end;
            Database::"Sales Cr.Memo Header": // 114
                begin
                    SalesCrMemoHeader.SetRange("No. Printed", 0);
                    SalesCrMemoHeader.ModifyAll("No. Printed", -1);
                end;
            Database::"Purch. Rcpt. Header": // 120
                begin
                    PurchReceiptHeader.SetRange("No. Printed", 0);
                    PurchReceiptHeader.ModifyAll("No. Printed", -1);
                    PurchRcptLine.SetFilter(Quantity, '<>0');
                    if PurchRcptLine.FindSet() then
                        repeat
                            PurchRcptLine."Quantity Invoiced" := PurchRcptLine.Quantity;
                            PurchRcptLine.Modify();
                        until PurchRcptLine.Next() = 0;
                end;
            Database::"Purch. Inv. Header": // 122
                begin
                    PurchInvHeader.SetRange("No. Printed", 0);
                    PurchInvHeader.ModifyAll("No. Printed", -1);
                end;
            Database::"Purch. Cr. Memo Hdr.": // 124
                begin
                    PurchCrMemoHeader.SetRange("No. Printed", 0);
                    PurchCrMemoHeader.ModifyAll("No. Printed", -1);
                end;
            Database::Job: // 167
                Job.ModifyAll(Status, Job.Status::Completed);
            Database::"Assembly Header": // 900
                AssembleToOrderLink.DeleteAll();
            Database::Contact: // 5050
                CleanTable(Database::"Segment Line", TableType::Master, true); // 5077
            Database::Opportunity: // 5092
                begin
                    Opportunity.SetFilter(Status, '<>%1', Opportunity.Status::"Not Started");
                    Opportunity.ModifyAll(Status, Opportunity.Status::"Not Started");
                end;
            Database::"Fixed Asset": // 5600
                begin
                    FixedAsset.ModifyAll(FixedAsset."Main Asset/Component", FixedAsset."Main Asset/Component"::" ");
                    FixedAsset.ModifyAll(FixedAsset."Component of Main Asset", '');
                end;
            Database::"Capacity Ledger Entry": // 5832
                begin
                    CapacityLedgerEntry.SetFilter("Order No.", '<>%1', '');
                    CapacityLedgerEntry.ModifyAll("Order No.", '');
                    CapacityLedgerEntry.ModifyAll("Order Line No.", 0);
                end;
            Database::"Service Header": // 5900
                begin
                    ServiceLine.ModifyAll("Appl.-to Service Entry", 0);
                    ServiceLine.DELETEALL(true);
                end;
            Database::"Service Contract Header": // 5965
                begin
                    ServiceContractHeader.SetFilter(Status, '<>0');
                    ServiceContractHeader.ModifyAll(Status, 0);
                end;
            Database::"Service Invoice Header":// 5992
                begin
                    ServiceInvoiceHeader.SetRange("No. Printed", 0);
                    ServiceInvoiceHeader.ModifyAll("No. Printed", -1);
                end;
            Database::"Service Cr.Memo Header": // 5994
                begin
                    ServiceCrMemoHeader.SetRange("No. Printed", 0);
                    ServiceCrMemoHeader.ModifyAll("No. Printed", -1);
                end;
            Database::"Return Shipment Header": // 6650
                begin
                    ReturnShipmentHeader.SetRange("No. Printed", 0);
                    ReturnShipmentHeader.ModifyAll("No. Printed", -1);
                end;
            Database::"Return Receipt Header": // 6660
                begin
                    ReturnReceiptHeader.SetRange("No. Printed", 0);
                    ReturnReceiptHeader.ModifyAll("No. Printed", -1);
                end;
            Database::"Posted Whse. Receipt Header": // 7318
                begin
                    PostedWhseReceiptHeader.ModifyAll("Document Status", PostedWhseReceiptHeader."Document Status"::"Completely Put Away");
                end;
            Database::"Warehouse Shipment Header": // 7320
                begin
                    WarehouseShipmentHeader.ModifyAll(Status, WarehouseShipmentHeader.Status::Open);
                    if WarehouseShipmentLine.FindSet() then
                        repeat
                            WarehouseShipmentLine."Qty. Picked" := WarehouseShipmentLine."Qty. Shipped";
                            WarehouseShipmentLine.Modify();
                        until WarehouseShipmentLine.Next() = 0;
                end;
            Database::"Production BOM Header": // 99000771
                begin
                    Item.ModifyAll("Production BOM No.", '');
                    ProductionBOMHeader.ModifyAll(Status, ProductionBOMHeader.Status::New);
                    ProductionBOMVersion.ModifyAll(Status, ProductionBOMVersion.Status::New);
                end;
        end;
    end;

    local procedure SetTableFilters(var pRecordRef: RecordRef);
    var
        FldRef: FieldRef;
        SalesDocumentType: Enum "Sales Document Type";
        PurchaseDocumentType: Enum "Purchase Document Type";
    begin
        case pRecordRef.Number of
        /*
                    Database::"Sales Header",
                    Database::"Sales Line",
                    Database::"Sales Comment Line":
                        begin
                            FldRef := pRecordRef.Field(1);
                            FldRef.SetFilter('<>%1&<>%2', SalesDocumentType::Quote, SalesDocumentType::"Blanket Order");
                        end;

                    Database::"Purchase Header",
                    Database::"Purchase Line",
                    Database::"Purch. Comment Line":
                        begin
                            FldRef := pRecordRef.Field(1);
                            FldRef.SetFilter('<>%1&<>%2', PurchaseDocumentType::Order, PurchaseDocumentType::"Blanket Order");
                        end;
        */
        end;
    end;
}
