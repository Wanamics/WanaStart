table 87102 "Fixed Asset Import Buffer"
{
    Caption = 'Fixed Asset Import Buffer', Locked = true;
    DataClassification = ToBeClassified;
    TableType = Temporary;

    fields
    {
        field(1000; "Row No."; Integer)
        {
            Caption = 'Row No.', Locked = true;
        }
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; "FA Class Code"; Code[10])
        {
            Caption = 'FA Class Code';
            TableRelation = "FA Class";

        }
        field(6; "FA Subclass Code"; Code[10])
        {
            Caption = 'FA Subclass Code';
            TableRelation = "FA Subclass";
        }
        field(7; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));
        }
        field(8; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
        }
        field(9; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(10; "FA Location Code"; Code[10])
        {
            Caption = 'FA Location Code';
            TableRelation = "FA Location";
        }
        field(11; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(12; "Main Asset/Component"; Enum "FA Component Type")
        {
            Caption = 'Main Asset/Component';
            Editable = false;
        }
        field(13; "Component of Main Asset"; Code[20])
        {
            Caption = 'Component of Main Asset';
            Editable = false;
            TableRelation = "Fixed Asset";
        }
        field(15; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(16; "Responsible Employee"; Code[20])
        {
            Caption = 'Responsible Employee';
            TableRelation = Employee;
        }
        field(17; "Serial No."; Text[50])
        {
            Caption = 'Serial No.';
        }
        field(21; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(23; "Maintenance Vendor No."; Code[20])
        {
            Caption = 'Maintenance Vendor No.';
            TableRelation = Vendor;
        }
        field(24; "Under Maintenance"; Boolean)
        {
            Caption = 'Under Maintenance';
        }
        field(25; "Next Service Date"; Date)
        {
            Caption = 'Next Service Date';
        }
        field(26; Inactive; Boolean)
        {
            Caption = 'Inactive';
        }
        field(103; "Depreciation Method"; Enum "FA Depreciation Method")
        {
            Caption = 'Depreciation Method';
        }
        field(104; "Depreciation Starting Date"; Date)
        {
            Caption = 'Depreciation Starting Date';
        }
        field(106; "No. of Depreciation Years"; Decimal)
        {
            BlankZero = true;
            Caption = 'No. of Depreciation Years';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
        }
        field(107; "No. of Depreciation Months"; Decimal)
        {
            BlankZero = true;
            Caption = 'No. of Depreciation Months';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
        }
        field(108; "Fixed Depr. Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Fixed Depr. Amount';
            MinValue = 0;
        }
        field(109; "Declining-Balance %"; Decimal)
        {
            Caption = 'Declining-Balance %';
            DecimalPlaces = 2 : 8;
            MaxValue = 100;
            MinValue = 0;
        }
        field(110; "Depreciation Table Code"; Code[10])
        {
            Caption = 'Depreciation Table Code';
            TableRelation = "Depreciation Table Header";
        }
        field(113; "FA Posting Group"; Code[20])
        {
            Caption = 'FA Posting Group';
            TableRelation = "FA Posting Group";
        }
        field(114; "Depreciation Ending Date"; Date)
        {
            Caption = 'Depreciation Ending Date';
        }
        field(130; "Acquisition Date"; Date)
        {
            Caption = 'Acquisition Date';
        }
        field(1015; "Acquisition Cost"; Decimal)
        {
            Caption = 'Acquisition Cost';
        }
        field(1016; Depreciation; Decimal)
        {
            Caption = 'Depreciation';
        }
    }

    keys
    {
        key(PK; "Row No.")
        {
            Clustered = true;
        }
    }
    var
        ExcelBuffer: Record "Excel Buffer" temporary;
        Helper: Codeunit "Wan Helper";

    procedure Load(IStream: InStream)
    var
        Next: Integer;
    begin
        ExcelBuffer.OpenBookStream(IStream, ExcelBuffer.SelectSheetsNameStream(IStream));
        ExcelBuffer.ReadSheet();
        ExcelBuffer.SetFilter("Row No.", '>1');
        ExcelBuffer.SetFilter("Column No.", Select());
        if ExcelBuffer.FindSet then
            repeat
                Rec."Row No." := ExcelBuffer."Row No.";
                Rec.Init();
                repeat
                    ImportCell(ExcelBuffer."Column No.", ExcelBuffer."Cell Value as Text");
                    Next := ExcelBuffer.Next;
                until (Next = 0) or (ExcelBuffer."Row No." <> Rec."Row No.");
                Rec.Insert();
            until Next = 0;
    end;

    local procedure Select() ReturnValue: Text
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingType: Enum "Gen. Journal Line FA Posting Type";
    begin
        Helper.SelectFrom(ExcelBuffer);
        Helper.SelectNext(FixedAsset.FieldCaption("No."));
        Helper.SelectNext(FixedAsset.FieldCaption(Description));
        Helper.SelectNext(FixedAsset.FieldCaption("FA Class Code"));
        Helper.SelectNext(FixedAsset.FieldCaption("FA Subclass Code"));
        Helper.SelectNext(FixedAsset.FieldCaption("Global Dimension 1 Code"));
        Helper.SelectNext(FixedAsset.FieldCaption("Global Dimension 2 Code"));
        Helper.SelectNext(FADepreciationBook.FieldCaption("FA Posting Group"));
        Helper.SelectNext(FADepreciationBook.FieldCaption("Acquisition Date"));
        Helper.SelectNext(FADepreciationBook.FieldCaption("Depreciation Method"));
        Helper.SelectNext(FADepreciationBook.FieldCaption("No. of Depreciation Years"));
        Helper.SelectNext(FADepreciationBook.FieldCaption("Depreciation Starting Date"));
        Helper.SelectNext(Format(FAPostingType::"Acquisition Cost"));
        Helper.SelectNext(Format(FAPostingType::Depreciation));
        exit(Helper.Select());
    end;

    local procedure ImportCell(pColumnNo: Integer; pCell: Text)
    begin
        case pColumnNo of
            1:
                "No." := pCell;
            2:
                Description := pCell;
            3:
                "FA Class Code" := pCell;
            4:
                "FA Subclass Code" := pCell;
            5:
                "Global Dimension 1 Code" := pCell;
            6:
                "Global Dimension 2 Code" := pCell;
            7:
                "FA Posting Group" := pCell;
            8:
                "Acquisition Date" := Helper.ToDate(pCell);
            9:
                Evaluate("Depreciation Method", pCell);
            10:
                "No. of Depreciation Years" := Helper.ToDecimal(pCell);
            11:
                "Depreciation Starting Date" := Helper.ToDate(pCell);
            12:
                "Acquisition Cost" := Helper.ToDecimal(pCell);
            13:
                Depreciation := Helper.ToDecimal(pCell)
        end;
    end;
}
