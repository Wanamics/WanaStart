table 87106 "wanaStart Import FR Line"
{
    Caption = 'Import FR Line';
    DataClassification = ToBeClassified;
    DrillDownPageId = "wanaStart Import Lines";

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; JournalCode; Code[10])
        {
            Caption = 'JournalCode';
        }
        field(3; EcritureNum; Code[20])
        {
            Caption = 'EcritureNum';
        }
        field(4; EcritureDate; Date)
        {
            Caption = 'EcritureDate';
        }
        field(5; CompteNum; Code[20])
        {
            Caption = 'CompteNum';
        }
        field(6; CompAuxNum; Code[20])
        {
            Caption = 'CompAuxNum';
        }
        field(7; PieceRef; Code[20])
        {
            Caption = 'PieceRef';
        }
        field(8; PieceDate; Date)
        {
            Caption = 'PieceDate';
        }
        field(9; EcritureLib; Text[100])
        {
            Caption = 'EcritureLib';
        }
        field(10; Debit; Decimal)
        {
            Caption = 'Debit';
            BlankZero = true;
        }
        field(11; Credit; Decimal)
        {
            Caption = 'Credit';
            BlankZero = true;
        }
        field(12; EcritureLet; Code[20])
        {
            Caption = 'EcritureLet';
        }
        field(13; DateLet; Date)
        {
            Caption = 'DateLet';
        }
        field(14; ValidDate; Date)
        {
            Caption = 'ValidDate';
        }
        field(15; MontantDev; Decimal)
        {
            Caption = 'MontantDev';
        }
        field(16; Idevise; Code[10])
        {
            Caption = 'Idevise';
        }
        field(100; Amount; Decimal)
        {
            Caption = 'Amount';
            BlankZero = true;
        }
        field(101; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            BlankZero = true;
            DecimalPlaces = 2 : 2;
        }
        field(102; Open; Boolean)
        {
            Caption = 'Open';
            BlankZero = true;
        }
    }
    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
        key(Journal; JournalCode, EcritureDate, EcritureNum, PieceRef) { SumIndexFields = Amount; MaintainSqlIndex = false; }
        key(Compte; CompteNum, CompAuxNum, Open) { SumIndexFields = Amount; MaintainSqlIndex = false; }
    }
}
