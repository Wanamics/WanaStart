table 81910 "wanaStart Direct Posting Buf."
{
    Caption = 'Check Direct Posting Buf.';
    DataClassification = ToBeClassified;
    TableType = Temporary;

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
            DataClassification = ToBeClassified;
        }
        field(2; "Table Caption"; Text[50])
        {
            Caption = 'Table Caption';
            DataClassification = ToBeClassified;
        }
        field(3; "Posting Group 1"; Code[20])
        {
            Caption = 'Posting Group 1';
            DataClassification = ToBeClassified;
        }
        field(4; "Posting Group 2"; Code[20])
        {
            Caption = 'Posting Group 2';
            DataClassification = ToBeClassified;
        }
        field(5; "Field No."; Integer)
        {
            Caption = 'Field No.';
            DataClassification = ToBeClassified;
        }
        field(6; "Field Caption"; Text[50])
        {
            Caption = 'Field Caption';
            DataClassification = ToBeClassified;
        }
        field(7; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = ToBeClassified;
        }
        field(8; "Account Name"; Text[100])
        {
            Caption = 'Account Name';
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; "Table No.", "Posting Group 1", "Posting Group 2", "Field No.")
        {
            Clustered = true;
        }
    }

}
