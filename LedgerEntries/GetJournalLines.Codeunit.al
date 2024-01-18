codeunit 87106 "wanaStart Get Journal Lines"
{
    TableNo = "Gen. Journal Line";
    trigger OnRun()
    var
        ConfirmMsg: Label 'Warning, %1 line(s) of this journal will be deleted.';
        ContinueMsg: Label 'Do-you want to continue?';
        StartDateTime: DateTime;
        DoneMsg: Label '%1 lines inserted in %2.';
    begin
        if not Rec.IsEmpty() then
            if not Confirm(ConfirmMsg + '\' + ContinueMsg, false, Rec.Count()) then
                Error('');

        Rec.DeleteAll(true);

        StartDateTime := CurrentDateTime;
        GetLines(Rec);
        Message(DoneMsg, Rec.Count(), CurrentDateTime - StartDateTime);
    end;

    var
        MapAccount: Record "wanaStart Map Account";
        MapSourceCode: Record "wanaStart Map Source Code";
        VATPostingSetup: Record "VAT Posting Setup";
        UnrealizedVAT: Boolean;

    local procedure GetLines(pRec: Record "Gen. Journal Line")
    var
        ProgressMsg: Label 'FR Tax Audit Import';
        ProgressDialog: Codeunit "Excel Buffer Dialog Management";
        ImportLine: Record "wanaStart Import FR Line";
        Default: Record "Gen. Journal Line";
    begin
        Default := pRec;
        ProgressDialog.Open(ProgressMsg);
        if ImportLine.FindSet then
            repeat
                ProgressDialog.SetProgress(ImportLine."Line No.");

                if (ImportLine.CompteNum <> MapAccount."From Account No.") or (ImportLine.CompAuxNum <> MapAccount."From SubAccount No.") then
                    MapAccount.Get(ImportLine.CompteNum, ImportLine.CompAuxNum);
                if ImportLine.JournalCode <> MapSourceCode."From Source Code" then
                    MapSourceCode.Get(ImportLine.JournalCode);

                if not MapAccount.Skip and
                    not MapSourceCode.Skip and
                    (not UnrealizedVAT or (MapAccount."Gen. Posting Type" = MapAccount."Gen. Posting Type"::" ") or (MapAccount."Gen. Posting Type" <> MapSourceCode."Gen. Posting Type")) then begin
                    pRec := Default;
                    Set(pRec, ImportLine);
                    OnBeforeInsert(pRec, ImportLine);
                    pRec.Insert(true);
                    MapDimensions(pRec);
                    OnAfterInsert(pRec, ImportLine);
                end;
            until ImportLine.Next() = 0;
    end;

    local procedure Set(var pRec: Record "Gen. Journal Line"; ImportLine: Record "wanaStart Import FR Line")
    begin
        pRec.Init();
        pRec."Line No." := ImportLine."Line No." * 10000;
        pRec.Validate("Account Type", MapAccount."Account Type");
        pRec.Validate("Account No.", MapAccount."Account No.");
        pRec."Source Code" := MapSourceCode."Source Code";
        pRec.Validate("Posting Date", ImportLine.EcritureDate);
        if MapSourceCode.Start then begin
            pRec.Validate("Document No.", ImportLine.EcritureNum);
            pRec.Validate("External Document No.", ImportLine.PieceRef)
        end else
            pRec.Validate("Document No.", ImportLine.PieceRef);
        // if (pRec."Document No." <> xDocumentNo) or (xPieceRef = '') then begin
        //     xDocumentNo := pRec."Document No.";
        //     xSuffix := 0;
        // end else begin
        //     if CsvBuffer.Value <> xPieceRef then
        //         xSuffix += 1;
        //     if xSuffix > 0 then
        //         pRec.Validate("Document No.", pRec."Document No." + '.' + Format(xSuffix));
        // end;
        // xPieceRef := CsvBuffer.Value;

        if MapSourceCode."Gen. Posting Type" <> MapSourceCode."Gen. Posting Type"::" " then begin
            if IsInvoice(MapSourceCode."Gen. Posting Type", ImportLine) then
                pRec.Validate("Document Type", pRec."Document Type"::Invoice)
            else
                pRec.Validate("Document Type", pRec."Document Type"::"Credit Memo");
            if pRec."Account Type" in [pRec."Account Type"::Vendor, pRec."Account Type"::Customer] then begin
                GetVATPostingSetup(pRec);
                UnrealizedVAT := ImportLine.Open and (VATPostingSetup."VAT %" <> 0) and (VATPostingSetup."Unrealized VAT Type" = VATPostingSetup."Unrealized VAT Type"::Percentage);
                if UnrealizedVAT then begin
                    pRec.Validate("Bal. Account No.", MapSourceCode."Bal. Account No.");
                    // SetBalanceVAT(pRec);
                    pRec.Validate("Bal. Gen. Posting Type", MapSourceCode."Gen. Posting Type");
                    pRec.Validate("Bal. VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
                    pRec.Validate("Bal. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group")
                end
                // else
                //     pRec."Sales/Purch. (LCY)" := ImportLine.Amount / (1 + VATPostingSetup."VAT %" / 100);
            end
            else
                if UnrealizedVAT then
                    pRec.Validate("Bal. Account No.", MapSourceCode."Bal. Account No.");
        end;

        pRec.Validate(Amount, ImportLine.Amount);
        if not UnrealizedVAT and (pRec."Account Type" in [pRec."Account Type"::Vendor, pRec."Account Type"::Customer]) then
            pRec."Sales/Purch. (LCY)" := ImportLine.Amount / (1 + VATPostingSetup."VAT %" / 100);

        pRec.Validate("Document Date", ImportLine.PieceDate);
        if pRec."Account No." = '' then
            pRec.Description := CopyStr('!' + MapAccount."From Account No." + '|' + MapAccount."From SubAccount No." + '!' + pRec.Description, 1, MaxStrLen(pRec.Description))
        else
            pRec.Validate(Description, ImportLine.EcritureLib);
        if (ImportLine.EcritureLet <> '') and (pRec."Account Type" in [pRec."Account Type"::Customer, pRec."Account Type"::Vendor]) then
            pRec.Validate("Applies-to ID", ImportLine.EcritureLet);


        // if ((pRec."Account Type" = pRec."Account Type"::Vendor) or (pRec."Bal. Account Type" = pRec."Account Type"::Vendor)) and
        //     (PurchaseSetup."Ext. Doc. No. Mandatory")
        // or
        //    ((pRec."Account Type" = pRec."Account Type"::Customer) or (pRec."Bal. Account Type" = pRec."Account Type"::Customer)) and
        //     (SalesSetup."Ext. Doc. No. Mandatory") then
        //     pRec.TestField("External Document No."); // := pRec."Document No.";
        //TODO
        /*
        if (pRec."Account Type" = pRec."Account Type"::Vendor) and
            (pRec."External Document No." <> '') and
            (pRec."Document Type" in [pRec."Document Type"::Invoice, pRec."Document Type"::"Credit Memo"]) then
            SetUniqueExternalDocumentNo(pRec);
        */
    end;

    local procedure IsInvoice(pGenPostingType: enum "General Posting Type"; ImportLine: Record "wanaStart Import FR Line"): Boolean
    begin
        case pGenPostingType of
            pGenPostingType::Purchase:
                exit((ImportLine.CompAuxNum <> '') xor (ImportLine.Amount >= 0));
            pGenPostingType::Sale:
                exit((ImportLine.CompAuxNum <> '') xor (ImportLine.Amount <= 0));
        end;
    end;

    local procedure GetVATPostingSetup(pRec: Record "Gen. Journal Line")
    var
        VPS: Record "VAT Posting Setup";
    begin
        if MapAccount."VAT Prod. Posting Group" <> '' then
            VPS."VAT Prod. Posting Group" := MapAccount."VAT Prod. Posting Group"
        else
            VPS."VAT Prod. Posting Group" := MapSourceCode."VAT Prod. Posting Group";
        VPS."VAT Bus. Posting Group" := MapAccount.GetVATBusPostingGroup();
        if (VPS."VAT Bus. Posting Group" <> VATPostingSetup."VAT Bus. Posting Group") or
            (VPS."VAT Prod. Posting Group" <> VATPostingSetup."VAT Prod. Posting Group") then
            VATPostingSetup.Get(VPS."VAT Bus. Posting Group", VPS."VAT Prod. Posting Group");
    end;

    // local procedure SetBalanceVAT(var pRec: Record "Gen. Journal Line")
    // var
    //     VATBusPostingGroup: Code[20];
    // begin
    // pRec.Validate("Bal. Gen. Posting Type", MapSourceCode."Gen. Posting Type");
    // case pRec."Account Type" of
    //     pRec."Account Type"::Customer:
    //         SetCustomerVATBusPostingGroup(pRec);
    //     pRec."Account Type"::Vendor:
    //         SetVendorVATBusPostingGroup(pRec);
    // end;
    // if MapAccount."VAT Prod. Posting Group" <> '' then
    //     pRec.Validate("Bal. VAT Prod. Posting Group", MapAccount."VAT Prod. Posting Group")
    // else
    //     if MapSourceCode."VAT Prod. Posting Group" <> '' then
    //         pRec.Validate("Bal. VAT Prod. Posting Group", MapSourceCode."VAT Prod. Posting Group");
    // pRec.TestField("Bal. VAT Prod. Posting Group");
    //     pRec.Validate("Bal. VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
    //     pRec.Validate("Bal. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group")
    // end;

    // local procedure SetCustomerVATBusPostingGroup(var pRec: Record "Gen. Journal Line");
    // var
    //     Customer: Record Customer;
    // begin
    //     Customer.SetLoadFields("VAT Bus. Posting Group");
    //     if Customer.Get(pRec."Account No.") then
    //         pRec.Validate("Bal. VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
    // end;

    // local procedure SetVendorVATBusPostingGroup(var pRec: Record "Gen. Journal Line");
    // var
    //     Vendor: Record Vendor;
    // begin
    //     Vendor.SetLoadFields("VAT Bus. Posting Group");
    //     if Vendor.Get(pRec."Account No.") then
    //         pRec.Validate("Bal. VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
    // end;

    /*TODO
    local procedure SetUniqueExternalDocumentNo(var pRec: Record "Gen. Journal Line")
    var
        lRec: Record "Gen. Journal Line";
        i: Integer;
    begin
        lRec.SetRange("Journal Template Name", pRec."Journal Template Name");
        lRec.SetRange("Journal Batch Name", pRec."Journal Batch Name");
        lRec.SetRange("Account Type", pRec."Account Type");
        lRec.SetRange("Account No.", prec."Account No.");
        lRec.SetRange("External Document No.", pRec."External Document No.");
        if lRec.FindSet() then
            repeat
                i += 1;
                pRec."External Document No." := lRec."External Document No." + '.' + format(i);
                lRec.SetRange("External Document No.", pRec."External Document No.");
            until lRec.IsEmpty();
    end;
    */

    local procedure MapDimensions(var pRec: Record "Gen. Journal Line"): Boolean
    var
        DimensionSetId: Integer;
    begin
        DimensionSetId := pRec."Dimension Set ID";
        if MapAccount."Dimension 1 Code" <> '' then
            pRec.ValidateShortcutDimCode(1, MapAccount."Dimension 1 Code");
        if MapAccount."Dimension 2 Code" <> '' then
            pRec.ValidateShortcutDimCode(2, MapAccount."Dimension 2 Code");
        if MapAccount."Dimension 3 Code" <> '' then
            pRec.ValidateShortcutDimCode(3, MapAccount."Dimension 3 Code");
        if MapAccount."Dimension 4 Code" <> '' then
            pRec.ValidateShortcutDimCode(4, MapAccount."Dimension 4 Code");
        if pRec."Dimension Set ID" <> DimensionSetId then
            pRec.Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsert(var pRec: Record "Gen. Journal Line"; var pImportLine: Record "wanaStart Import FR Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsert(var pRec: Record "Gen. Journal Line"; var pImportLine: Record "wanaStart Import FR Line")
    begin
    end;
}