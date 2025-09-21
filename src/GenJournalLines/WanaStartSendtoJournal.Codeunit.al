codeunit 87106 "WanaStart Send to Journal"
{
    TableNo = "Gen. Journal Line";

    var
        MapAccount: Record "WanaStart Map Account";
        MapSourceCode: Record "WanaStart Map Source Code";
        VATPostingSetup: Record "VAT Posting Setup";
        Default: Record "Gen. Journal Line";
        VendBalAccountNo, CustBalAccountNo : code[20];
        DocumentNoPrefix: Code[10];

    procedure Initialize(pDefault: Record "Gen. Journal Line"; pVendBalAccountNo: code[20]; pCustBalAccountNo: code[20]; pDocumentNoPrefix: Code[10])
    begin
        Default := pDefault;
        VendBalAccountNo := pVendBalAccountNo;
        CustBalAccountNo := pCustBalAccountNo;
        DocumentNoPrefix := pDocumentNoPrefix;
    end;

    procedure GetLine(pImportLine: Record "wanaStart Import Line")// pDefault: Record "Gen. Journal Line")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if pImportLine.JournalCode <> MapSourceCode."From Source Code" then
            MapSourceCode.Get(pImportLine.JournalCode);
        if MapSourceCode.Skip then
            exit;
        if (pImportLine.CompteNum <> MapAccount."From Account No.") or (pImportLine.CompAuxNum <> MapAccount."From SubAccount No.") then
            MapAccount.Get(pImportLine.CompteNum, pImportLine.CompAuxNum);
        if MapAccount.Skip then
            exit;

        if (MapAccount."WanaStart Source Posting Type" = "WanaStart Posting Type"::" ") or
                (MapAccount."WanaStart Source Posting Type" <> MapSourceCode."WanaStart Posting Type") and (MapSourceCode."WanaStart Posting Type" <> "WanaStart Posting Type"::Opening) then begin
            // pDefault."Line No." := GenJournalLine."Line No.";
            // GenJournalLine := pDefault;
            Set(GenJournalLine, pImportLine);
            OnBeforeInsert(GenJournalLine, pImportLine);
            GenJournalLine.Insert(true);
            MapDimensions(GenJournalLine);
            OnAfterInsert(GenJournalLine, pImportLine);
            if (MapSourceCode."WanaStart Posting Type" = "WanaStart Posting Type"::Opening) and
                    (GenJournalLine."Document Type" in ["Gen. Journal Document Type"::Invoice, "Gen. Journal Document Type"::"Credit Memo"]) then
                // Balance(GenJournalLine, GenJournalLine."Document No."); //pImportLine.EcritureNum);
                Balance(GenJournalLine, DocumentNoPrefix + pImportLine.JournalCode);
        end;
    end;

    local procedure Set(var pRec: Record "Gen. Journal Line"; pImportLine: Record "wanaStart Import Line")
    begin
        // pRec.Init();
        if pImportLine."Split Line No." = 0 then
            Default."Line No." := pImportLine."Line No." * 10000
        else
            Default."Line No." += 1;
        pRec := Default;
        pRec."Source Code" := MapSourceCode."Source Code";
        pRec.Validate("Account Type", MapAccount."Account Type");
        pRec.Validate("Account No.", MapAccount."Account No.");
        // pRec."Source Code" := MapSourceCode."Source Code";
        // if MapSourceCode."WanaStart Posting Type" = "WanaStart Posting Type"::Opening then
        //     pRec.Validate("Posting Date", pImportLine.EcritureDate - 1)
        // else
        pRec.Validate("Posting Date", pImportLine.EcritureDate);

        Case MapSourceCode."Document No." of
            MapSourceCode."Document No."::EcritureNum:
                pRec.Validate("Document No.", DocumentNoPrefix + pImportLine.EcritureNum);
            MapSourceCode."Document No."::PieceRef:
                pRec.Validate("Document No.", DocumentNoPrefix + pImportLine.PieceRef);
            MapSourceCode."Document No."::"External Document No.":
                pRec.Validate("Document No.", DocumentNoPrefix + pImportLine."_External Document No.");
            MapSourceCode."Document No."::"From Line":
                begin
                    pImportLine.TestField("Document No.");
                    pRec.Validate("Document No.", DocumentNoPrefix + pImportLine."Document No.");
                end;
        end;
        Case MapSourceCode."External Document No." of
            MapSourceCode."External Document No."::EcritureNum:
                pRec.Validate("External Document No.", pImportLine.EcritureNum);
            MapSourceCode."External Document No."::PieceRef:
                pRec.Validate("External Document No.", pImportLine.PieceRef);
            MapSourceCode."External Document No."::"External Document No.":
                pRec.Validate("External Document No.", pImportLine."_External Document No.");
            MapSourceCode."External Document No."::None:
                ;
        end;

        if (MapSourceCode."WanaStart Posting Type" <> "WanaStart Posting Type"::" ") and
                (pRec."Account Type" <> "Gen. Journal Account Type"::Employee) and
                not pImportLine."No VAT" and
                ((MapSourceCode."WanaStart Posting Type" <> "WanaStart Posting Type"::Opening) or
                (MapAccount."Account Type" in ["Gen. Journal Account Type"::Customer, "Gen. Journal Account Type"::Vendor])) then begin
            if IsInvoice(MapSourceCode."WanaStart Posting Type", pImportLine) then
                pRec.Validate("Document Type", "Gen. Journal Document Type"::Invoice)
            else
                pRec.Validate("Document Type", "Gen. Journal Document Type"::"Credit Memo");
            if pRec."Account Type" in ["Gen. Journal Account Type"::Vendor, "Gen. Journal Account Type"::Customer] then
                SetVAT(pRec, pImportLine)
            else
                case MapSourceCode."WanaStart Posting Type" of
                    "WanaStart Posting Type"::Purchase:
                        pRec.Validate("Bal. Account No.", VendBalAccountNo);
                    "WanaStart Posting Type"::Sale:
                        pRec.Validate("Bal. Account No.", CustBalAccountNo);
                end;
        end;

        if (MapSourceCode."WanaStart Posting Type" = MapSourceCode."WanaStart Posting Type"::Opening) and (pRec."Bal. Account No." = '') then begin
            pRec.Validate("Document No.", DocumentNoPrefix + pImportLine.JournalCode);
            if pRec."External Document No." = '' Then
                pRec.Validate("External Document No.", pImportLine.PieceRef);
        end;
        pRec.Validate(Amount, pImportLine.Amount);
        pRec.Validate("Document Date", pImportLine.PieceDate);
        if pRec."Account No." = '' then
            pRec.Description := CopyStr('!' + MapAccount."From Account No." + '|' + MapAccount."From SubAccount No." + '!' + pRec.Description, 1, MaxStrLen(pRec.Description))
        else
            pRec.Validate(Description, pImportLine.EcritureLib);
        if pRec."Account Type" in ["Gen. Journal Account Type"::Vendor, "Gen. Journal Account Type"::Customer] then begin
            pRec."Sales/Purch. (LCY)" := pImportLine.Amount + pImportLine."VAT Amount";
            // if pImportLine."_Applies-to ID" <> '' then
            //     pRec.Validate("Applies-to ID", pImportLine."_Applies-to ID")
            // else
            if pImportLine.EcritureLet <> '' then
                pRec.Validate("Applies-to ID", pImportLine.EcritureLet);
        end;
        if pImportLine."_Shortcut Dimension 1 Code" <> '' then
            pRec."Shortcut Dimension 1 Code" := pImportLine."_Shortcut Dimension 1 Code"
        else if MapAccount."Dimension 1 Code" <> '' then
            pRec."Shortcut Dimension 1 Code" := MapAccount."Dimension 1 Code";
        if pImportLine."_Shortcut Dimension 2 Code" <> '' then
            pRec."Shortcut Dimension 2 Code" := pImportLine."_Shortcut Dimension 2 Code"
        else if MapAccount."Dimension 2 Code" <> '' then
            pRec."Shortcut Dimension 2 Code" := MapAccount."Dimension 2 Code";
    end;

    local procedure IsInvoice(pGenPostingType: enum "WanaStart Posting Type"; ImportLine: Record "wanaStart Import Line"): Boolean
    begin
        case pGenPostingType of
            "WanaStart Posting Type"::Purchase:
                exit((ImportLine.CompAuxNum <> '') xor (ImportLine.Amount >= 0));
            "WanaStart Posting Type"::Sale:
                exit((ImportLine.CompAuxNum <> '') xor (ImportLine.Amount <= 0));
            "WanaStart Posting Type"::Opening:
                if MapAccount."Account Type" = "Gen. Journal Account Type"::Vendor then
                    exit(ImportLine.Amount <= 0)
                else
                    exit(ImportLine.Amount >= 0);
        end;
    end;

    local procedure GetVATPostingSetup(pRec: Record "Gen. Journal Line"; pImportLine: Record "wanaStart Import Line")
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
        VPS."VAT Bus. Posting Group" := MapAccount.GetVATBusPostingGroup();
        if (VPS."VAT Bus. Posting Group" <> VATPostingSetup."VAT Bus. Posting Group") or
            (VPS."VAT Prod. Posting Group" <> VATPostingSetup."VAT Prod. Posting Group") then
            if not VATPostingSetup.Get(VPS."VAT Bus. Posting Group", VPS."VAT Prod. Posting Group") then
                pImportLine.FieldError("VAT Prod. Posting Group");
    end;

    local procedure MapDimensions(var pRec: Record "Gen. Journal Line"): Boolean
    var
        DimensionSetId: Integer;
    begin
        DimensionSetId := pRec."Dimension Set ID";
        // if MapAccount."Dimension 1 Code" <> '' then
        //     pRec.ValidateShortcutDimCode(1, MapAccount."Dimension 1 Code");
        // if MapAccount."Dimension 2 Code" <> '' then
        //     pRec.ValidateShortcutDimCode(2, MapAccount."Dimension 2 Code");
        if MapAccount."Dimension 3 Code" <> '' then
            pRec.ValidateShortcutDimCode(3, MapAccount."Dimension 3 Code");
        if MapAccount."Dimension 4 Code" <> '' then
            pRec.ValidateShortcutDimCode(4, MapAccount."Dimension 4 Code");
        if pRec."Dimension Set ID" <> DimensionSetId then
            pRec.Modify(true);
    end;

    local procedure Balance(pRec: Record "Gen. Journal Line"; pDocumentNo: Code[20])
    var
        BalRec: Record "Gen. Journal Line";
    begin
        // BalRec."Journal Template Name" := pRec."Journal Template Name";
        // BalRec."Journal Batch Name" := pRec."Journal Batch Name";
        // BalRec."Line No." := pRec."Line No." + 1;
        // BalRec."Source Code" := pRec."Source Code";
        // BalRec."Reason Code" := pRec."Reason Code";
        // BalRec."Posting No. Series" := pRec."Posting No. Series";
        Default."Line No." += 1;
        BalRec := Default;
        BalRec."Source Code" := MapSourceCode."Source Code";
        BalRec.Validate("Posting Date", pRec."Posting Date");
        BalRec.Validate("Document No.", pDocumentNo);
        BalRec.Validate("External Document No.", pRec."External Document No.");
        BalRec.Validate("Account No.", pRec."Bal. Account No.");
        BalRec.Validate(Description, pRec.Description);
        BalRec.Validate(Amount, -pRec."Bal. VAT Base Amount (LCY)");
        BalRec.Insert(false);
    end;

    local procedure SetVAT(var pRec: Record "Gen. Journal Line"; pImportLine: Record "wanaStart Import Line")
    begin
        if pImportLine."Split Line No." <> 0 then begin
            pRec.Validate("Document No.", pRec."Document No." + '.' + Format(pImportLine."Split Line No."));
            pRec.Validate("External Document No.", pRec."External Document No." + '.' + Format(pImportLine."Split Line No."));
        end;
        // if MapSourceCode."WanaStart Posting Type" = "WanaStart Posting Type"::Opening then
        //     pRec.Validate("Document No.", Append(pRec."Document No.", pImportLine.PieceRef));

        if pRec."Account Type" = "Gen. Journal Account Type"::Vendor then begin
            pRec.Validate("Bal. Account No.", VendBalAccountNo);
            pRec.Validate("Bal. Gen. Posting Type", "General Posting Type"::Purchase);
        end else begin
            pRec.Validate("Bal. Account No.", CustBalAccountNo);
            pRec.Validate("Bal. Gen. Posting Type", "General Posting Type"::Sale);
        end;
        GetVATPostingSetup(pRec, pImportLine);
        pRec.Validate("Bal. VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        pRec.Validate("Bal. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure Append(pDocumentNo: Code[20]; pText: Text): Text
    var
        MaxLen: Integer;
    begin
        MaxLen := MaxStrLen(pDocumentNo) - StrLen(pDocumentNo) - 1;
        if StrLen(pText) > MaxLen then
            pText := pText.Remove(1, StrLen(pText) - MaxLen);
        exit(pDocumentNo + '|' + pText);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsert(var pRec: Record "Gen. Journal Line"; var pImportLine: Record "wanaStart Import Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsert(var pRec: Record "Gen. Journal Line"; var pImportLine: Record "wanaStart Import Line")
    begin
    end;
}