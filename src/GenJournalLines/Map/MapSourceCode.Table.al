table 87101 "wanaStart Map Source Code"
{
    Caption = 'Map SourceCode';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "From Source Code"; Code[10])
        {
            Caption = 'From Source Code';
            DataClassification = ToBeClassified;
            Editable = false;
            Width = 5;
        }
        field(2; "From Source Name"; Text[100])
        {
            Caption = 'From Source Name';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(3; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            DataClassification = ToBeClassified;
            TableRelation = "Source Code";
            Width = 6;
        }
        field(4; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account";
            Width = 6;
        }
        field(5; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(6; "Gen. Posting Type"; enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
            Width = 5;
            trigger OnValidate()
            var
                ImportLine: Record "WanaStart Import FR Line";
            begin
                if "Gen. Posting Type" <> xRec."Gen. Posting Type" then begin
                    ImportLine.SetRange(JournalCode, "From Source Code");
                    ImportLine.SetFilter(CompAuxNum, '<>%1', '');
                    ImportLine.ModifyAll("Gen. Posting Type", "Gen. Posting Type");
                    if ("Gen. Posting Type" = "Gen. Posting Type"::Purchase) or (xRec."Gen. Posting Type" = "Gen. Posting Type"::Purchase) then
                        UpdateMapAccount("Gen. Posting Type"::Purchase);
                    if ("Gen. Posting Type" = "Gen. Posting Type"::Sale) or (xRec."Gen. Posting Type" = "Gen. Posting Type"::Sale) then
                        UpdateMapAccount("Gen. Posting Type"::Sale);
                end;
            end;
        }
        field(9; "Skip"; Boolean)
        {
            Caption = 'Skip';
        }
        // field(10; "PieceRef as Document No."; Boolean)
        // {
        //     Caption = 'PieceRef as Document No.';
        // }
        // field(10; "VAT Account No. Filter"; Text[30])
        // {
        //     Caption = 'VAT Account No. Filter';
        //     Width = 6;
        // }
        field(11; "Document No."; Option)
        {
            Caption = 'Document No.';
            OptionMembers = "EcritureNum","PieceRef","From Line";
            OptionCaption = 'EcritureNum,PieceRef,From Line';
            Width = 5;
        }
        field(12; "External Document No."; Option)
        {
            Caption = 'External Document No.';
            OptionMembers = "PieceRef","EcritureNum","None";
            OptionCaption = 'PieceRef,EcritureNum,None';
            Width = 5;
        }
        field(100; "No. of Lines"; Integer)
        {
            Caption = 'No. of Lines';
            FieldClass = FlowField;
            CalcFormula = Count("WanaStart Import FR Line" where(JournalCode = field("From Source Code")));
            Editable = false;
            BlankZero = true;
            Width = 5;
        }
        field(101; "No. of Open Lines"; Integer)
        {
            Caption = 'No. of Open Lines';
            FieldClass = FlowField;
            CalcFormula = Count("WanaStart Import FR Line" where(JournalCode = field("From Source Code"), Open = const(true)));
            Editable = false;
            BlankZero = true;
            Width = 5;
        }
    }
    keys
    {
        key(PK; "From Source Code")
        {
            Clustered = true;
        }
    }

    local procedure UpdateMapAccount(pGenPostingType: Enum "General Posting Type")
    var
        MapAccount: Record "WanaStart Map Account";
        Progress: Codeunit "Progress Dialog";
    begin
        case pGenPostingType of
            "General Posting Type"::Purchase:
                MapAccount.SetRange("Account Type", MapAccount."Account Type"::Vendor);
            "General Posting Type"::Sale:
                MapAccount.SetRange("Account Type", MapAccount."Account Type"::Customer);
        end;
        MapAccount.SetAutoCalcFields("Amount Incl. VAT", "VAT Amount");
        Progress.OpenCopyCountMax('', MapAccount.Count);
        if MapAccount.FindSet() then
            repeat
                Progress.UpdateCopyCount();
                if MapAccount."Amount Incl. VAT" + MapAccount."VAT Amount" = 0 then
                    MapAccount."VAT %" := 0
                else
                    MapAccount."VAT %" := Round(Abs(MapAccount."VAT Amount" / (MapAccount."Amount Incl. VAT" + MapAccount."VAT Amount") * 100), 0.01);
                MapAccount.Modify(true);
            until MapAccount.Next() = 0;
    end;
}
