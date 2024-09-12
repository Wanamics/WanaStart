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
            Editable = false;
        }
        field(2; JournalCode; Code[10])
        {
            Caption = 'JournalCode', Locked = true;
            Editable = false;
            TableRelation = "wanaStart Map Source Code";
            Width = 5;
        }
        field(3; EcritureNum; Code[20])
        {
            Caption = 'EcritureNum', Locked = true;
            Width = 8;
        }
        field(4; EcritureDate; Date)
        {
            Caption = 'EcritureDate', Locked = true;
            Width = 6;
        }
        field(5; CompteNum; Code[20])
        {
            Caption = 'CompteNum', Locked = true;
            Editable = false;
            TableRelation = "wanaStart Map Account"."From Account No.";
            Width = 8;
        }
        field(6; CompAuxNum; Code[20])
        {
            Caption = 'CompAuxNum', Locked = true;
            Editable = false;
            TableRelation = "wanaStart Map Account"."From SubAccount No." where("From Account No." = field(CompteNum));
            Width = 8;
        }
        field(7; PieceRef; Code[20])
        {
            Caption = 'PieceRef', Locked = true;
            Width = 8;
            Editable = false;
        }
        field(8; PieceDate; Date)
        {
            Caption = 'PieceDate', Locked = true;
            Width = 6;
            Editable = false;
        }
        field(9; EcritureLib; Text[100])
        {
            Caption = 'EcritureLib', Locked = true;
            Editable = false;
        }
        field(10; Debit; Decimal)
        {
            Caption = 'Debit', Locked = true;
            BlankZero = true;
            Width = 8;
            Editable = false;
        }
        field(11; Credit; Decimal)
        {
            Caption = 'Credit', Locked = true;
            BlankZero = true;
            Width = 8;
            Editable = false;
        }
        field(12; EcritureLet; Code[20])
        {
            Caption = 'EcritureLet', Locked = true;
            Width = 5;
            Editable = false;
        }
        field(13; DateLet; Date)
        {
            Caption = 'DateLet', Locked = true;
            Width = 6;
            Editable = false;
        }
        field(14; ValidDate; Date)
        {
            Caption = 'ValidDate', Locked = true;
            Width = 6;
            Editable = false;
        }
        field(15; MontantDev; Decimal)
        {
            Caption = 'MontantDev', Locked = true;
            Width = 8;
            Editable = false;
        }
        field(16; Idevise; Code[10])
        {
            Caption = 'Idevise', Locked = true;
            Width = 5;
            Editable = false;
        }
        field(100; Amount; Decimal)
        {
            Caption = 'Amount';
            BlankZero = true;
            Width = 8;
            trigger OnValidate()
            begin
                Rec.Debit := 0;
                Rec.Credit := 0;
                if Rec.Amount > 0 then
                    Rec.Debit := Rec.Amount
                else
                    Rec.Credit := -Rec.Amount;
                Validate("VAT Amount", Amount * (1 - (1 / (1 + "VAT %"))));
            end;
        }
        field(101; Open; Boolean)
        {
            Caption = 'Open';
            BlankZero = true;
            Editable = false;
        }
        field(102; "VAT Amount"; Decimal)
        {
            Caption = 'VAT Amount';
            BlankZero = true;
            Width = 8;
            trigger OnValidate()
            begin
                if Amount + "VAT Amount" = 0 then
                    "VAT %" := 0
                else
                    "VAT %" := Round(-"VAT Amount" / (Amount + "VAT Amount") * 100, 0.01);
            end;
        }
        field(103; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            BlankZero = true;
            DecimalPlaces = 1 : 2;
            Width = 5;
            trigger OnValidate()
            begin
                "VAT Amount" := Round(-Amount * (1 - 1 / (1 + "VAT %" / 100)));
            end;
        }
        field(104; "Split Line No."; Integer)
        {
            Caption = 'Split Line No.';
            BlankZero = true;
            Editable = false;
        }
        field(105; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
            Width = 5;
            trigger OnValidate()
            begin
                Rec.TestField(CompAuxNum);
                Rec.TestField(Open);
            end;
        }
        field(106; "Document No."; Code[50])
        {
            Caption = 'Document No.';
            Width = 8;
        }
        field(107; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
            Width = 6;
        }
    }
    keys
    {
        key(PK; "Line No.", "Split Line No.")
        {
            Clustered = true;
        }
        key(Journal; JournalCode, EcritureNum) { SumIndexFields = Amount; MaintainSqlIndex = false; }
        key(Compte; CompteNum, CompAuxNum, Open) { SumIndexFields = Amount; MaintainSqlIndex = false; }
    }

    trigger OnDelete()
    var
        Rec2: Record "wanaStart Import FR Line";
    begin
        Rec.TestField("Split Line No.");
        Rec2.Get("Line No.", 0);
        Rec2.Validate(Amount, Rec2.Amount + Rec.Amount);
        Rec2.Validate("VAT Amount", Rec2."VAT Amount" + Rec."VAT Amount");
        Rec2.Modify(true);
    end;
}
