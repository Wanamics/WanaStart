table 87101 "wanaStart Map Source Code"
{
    Caption = 'Map SourceCode';
    DataClassification = ToBeClassified;
    LookupPageId = "WanaStart Map Source Codes";

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
        // field(4; "Bal. Account No."; Code[20])
        // {
        //     Caption = 'Bal. Account No.';
        //     DataClassification = ToBeClassified;
        //     TableRelation = "G/L Account";
        //     Width = 6;
        //     ObsoleteState = Removed;
        // }
        field(5; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(6; "WanaStart Posting Type"; enum "WanaStart Posting Type")
        {
            Caption = 'Posting Type';
            Width = 5;
            trigger OnValidate()
            var
                ImportLine: Record "wanaStart Import Line";
            begin
                if "WanaStart Posting Type" <> xRec."WanaStart Posting Type" then begin
                    ImportLine.SetRange(JournalCode, "From Source Code");
                    ImportLine.SetFilter(CompAuxNum, '<>%1', '');
                    ImportLine.ModifyAll("Posting Type", "WanaStart Posting Type");
                    if ("WanaStart Posting Type" = "WanaStart Posting Type"::Purchase) or (xRec."WanaStart Posting Type" = "WanaStart Posting Type"::Purchase) then
                        UpdateMapAccount("WanaStart Posting Type"::Purchase);
                    if ("WanaStart Posting Type" = "WanaStart Posting Type"::Sale) or (xRec."WanaStart Posting Type" = "WanaStart Posting Type"::Sale) then
                        UpdateMapAccount("WanaStart Posting Type"::Sale);
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
            OptionMembers = "EcritureNum","PieceRef","From Line","External Document No.";
            OptionCaption = 'EcritureNum,PieceRef,From Line,ExternalDocumentNo';
            Width = 5;
        }
        field(12; "External Document No."; Option)
        {
            Caption = 'External Document No.';
            OptionMembers = "PieceRef","EcritureNum","None","External Document No.";
            OptionCaption = 'PieceRef,EcritureNum,None,ExternalDocumentNo';
            Width = 5;
        }
        field(100; "No. of Lines"; Integer)
        {
            Caption = 'No. of Lines';
            FieldClass = FlowField;
            CalcFormula = Count("wanaStart Import Line" where(JournalCode = field("From Source Code")));
            Editable = false;
            BlankZero = true;
            Width = 5;
        }
        field(101; "No. of Open Lines"; Integer)
        {
            Caption = 'No. of Open Lines';
            FieldClass = FlowField;
            CalcFormula = Count("wanaStart Import Line" where(JournalCode = field("From Source Code"), Open = const(true)));
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
    fieldgroups
    {
        fieldgroup(DropDown; "From Source Code", "From Source Name") { }
    }

    local procedure UpdateMapAccount(pGenPostingType: Enum "WanaStart Posting Type")
    var
        MapAccount: Record "WanaStart Map Account";
        Progress: Codeunit "Progress Dialog";
    begin
        case pGenPostingType of
            "WanaStart Posting Type"::Purchase:
                MapAccount.SetRange("Account Type", MapAccount."Account Type"::Vendor);
            "WanaStart Posting Type"::Sale:
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
