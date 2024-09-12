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
        xImportLine: Record "wanaStart Import FR Line";
        Suffix: Integer;

    local procedure GetLines(pRec: Record "Gen. Journal Line")
    var
        ProgressMsg: Label 'Get Journal Lines';
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
        pRec."Line No." := ImportLine."Line No." * 10000 + ImportLine."Split Line No.";
        pRec.Validate("Account Type", MapAccount."Account Type");
        pRec.Validate("Account No.", MapAccount."Account No.");
        pRec."Source Code" := MapSourceCode."Source Code";
        pRec.Validate("Posting Date", ImportLine.EcritureDate);

        Case MapSourceCode."Document No." of
            MapSourceCode."Document No."::EcritureNum:
                pRec.Validate("Document No.", ImportLine.EcritureNum);
            MapSourceCode."Document No."::PieceRef:
                pRec.Validate("Document No.", ImportLine.PieceRef);
            MapSourceCode."Document No."::"From Line":
                begin
                    ImportLine.TestField("Document No.");
                    pRec.Validate("Document No.", ImportLine."Document No.");
                end
        end;
        Case MapSourceCode."External Document No." of
            MapSourceCode."External Document No."::EcritureNum:
                pRec.Validate("External Document No.", ImportLine.EcritureNum);
            MapSourceCode."External Document No."::PieceRef:
                pRec.Validate("External Document No.", ImportLine.PieceRef);
            MapSourceCode."External Document No."::None:
                ;
        end;

        if (ImportLine."Split Line No." <> 0) and
            (pRec."External Document No." <> '') and
            (pRec."Account Type" in [pRec."Account Type"::Vendor, pRec."Account Type"::Customer]) then
            pRec.Validate("External Document No.", pRec."External Document No." + '.' + Format(ImportLine."Split Line No."));

        if MapSourceCode."Gen. Posting Type" <> MapSourceCode."Gen. Posting Type"::" " then begin
            if pRec."Account Type" <> pRec."Account Type"::Employee then
                if IsInvoice(MapSourceCode."Gen. Posting Type", ImportLine) then
                    pRec.Validate("Document Type", pRec."Document Type"::Invoice)
                else
                    pRec.Validate("Document Type", pRec."Document Type"::"Credit Memo");
        end;

        if (pRec."Account Type" in [pRec."Account Type"::Vendor, pRec."Account Type"::Customer]) and
            ((MapSourceCode."Gen. Posting Type" <> MapSourceCode."Gen. Posting Type"::" ") or (ImportLine."VAT Prod. Posting Group" <> '')) then begin
            GetVATPostingSetup(pRec, ImportLine);
            UnrealizedVAT := ImportLine.Open and /*(VATPostingSetup."VAT %" <> 0) and */(VATPostingSetup."Unrealized VAT Type" = VATPostingSetup."Unrealized VAT Type"::Percentage);
            if UnrealizedVAT then begin
                // if ImportLine."VAT Prod. Posting Group" <> '' then
                //     pRec.Validate("Document No.", CopyStr(pRec."Document No." + '/' + ImportLine."VAT Prod. Posting Group", 1, MaxStrLen(pRec."Document No.")));
                pRec.Validate("Bal. Account No.", MapSourceCode."Bal. Account No.");
                // pRec.Validate("Bal. Gen. Posting Type", MapSourceCode."Gen. Posting Type");
                if pRec."Account Type" = pRec."Account Type"::Vendor then
                    pRec.Validate("Bal. Gen. Posting Type", pRec."Bal. Gen. Posting Type"::Purchase)
                else
                    pRec.Validate("Bal. Gen. Posting Type", pRec."Bal. Gen. Posting Type"::Sale);
                pRec.Validate("Bal. VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
                pRec.Validate("Bal. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group")
            end;
        end else
            if UnrealizedVAT and (MapSourceCode."Gen. Posting Type" <> MapSourceCode."Gen. Posting Type"::" ") then
                pRec.Validate("Bal. Account No.", MapSourceCode."Bal. Account No.");

        pRec.Validate(Amount, ImportLine.Amount);
        pRec.Validate("Document Date", ImportLine.PieceDate);
        if pRec."Account No." = '' then
            pRec.Description := CopyStr('!' + MapAccount."From Account No." + '|' + MapAccount."From SubAccount No." + '!' + pRec.Description, 1, MaxStrLen(pRec.Description))
        else
            pRec.Validate(Description, ImportLine.EcritureLib);
        if pRec."Account Type" in [pRec."Account Type"::Vendor, pRec."Account Type"::Customer] then begin
            pRec."Sales/Purch. (LCY)" := ImportLine.Amount + ImportLine."VAT Amount";
            if ImportLine.EcritureLet <> '' then
                pRec.Validate("Applies-to ID", ImportLine.EcritureLet);
        end;
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

    local procedure GetVATPostingSetup(pRec: Record "Gen. Journal Line"; pImportLine: Record "wanaStart Import FR Line")
    var
        VPS: Record "VAT Posting Setup";
    begin
        if pImportLine."VAT Prod. Posting Group" <> '' then
            VPS."VAT Prod. Posting Group" := pImportLine."VAT Prod. Posting Group"
        else
            if MapAccount."VAT Prod. Posting Group" <> '' then
                VPS."VAT Prod. Posting Group" := MapAccount."VAT Prod. Posting Group"
            else
                VPS."VAT Prod. Posting Group" := MapSourceCode."VAT Prod. Posting Group";
        // if VPS."VAT Prod. Posting Group" = '' then 
        //     Clear(VATPostingSetup)
        // else begin
        VPS."VAT Bus. Posting Group" := MapAccount.GetVATBusPostingGroup();
        if (VPS."VAT Bus. Posting Group" <> VATPostingSetup."VAT Bus. Posting Group") or
            (VPS."VAT Prod. Posting Group" <> VATPostingSetup."VAT Prod. Posting Group") then
            VATPostingSetup.Get(VPS."VAT Bus. Posting Group", VPS."VAT Prod. Posting Group");
        // end;
    end;

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