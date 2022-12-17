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
        }
        field(2; "From Source Name"; Text[100])
        {
            Caption = 'From Source Name';
            DataClassification = ToBeClassified;
        }
        field(3; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            DataClassification = ToBeClassified;
            TableRelation = "Source Code";
        }
        field(4; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account";
        }
        field(5; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(6; "Gen. Posting Type"; enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
        }
        field(9; "Skip"; Boolean)
        {
            Caption = 'Skip';
        }
    }
    keys
    {
        key(PK; "From Source Code")
        {
            Clustered = true;
        }
    }
}
