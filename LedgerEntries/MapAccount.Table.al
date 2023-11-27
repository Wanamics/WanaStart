table 87100 "wanaStart Map Account"
{
    Caption = 'Map Account';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "From Account No."; Code[20])
        {
            Caption = 'From Account No.';
            DataClassification = ToBeClassified;
        }
        field(2; "From SubAccount No."; Code[20])
        {
            Caption = 'From SubAccount No.';
        }
        field(3; "From Account Name"; Text[100])
        {
            Caption = 'From Account Name';
            DataClassification = ToBeClassified;
        }
        field(4; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                if "Account Type" <> xRec."Account Type" then begin
                    "Account No." := '';
                    "Template Code" := '';
                    "Gen. Posting Type" := "Gen. Posting Type"::" ";
                end;
            end;
        }
        field(5; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = ToBeClassified;
            TableRelation =
            if ("Account Type" = const("G/L Account")) "G/L Account"
                where("Account Type" = const(Posting), "Direct Posting" = const(true))
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Account Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Account Type" = const("IC Partner")) "IC Partner"
            else
            if ("Account Type" = const(Employee)) Employee;
        }
        field(6; "Template Code"; Code[20])
        {
            Caption = 'Template Code';
            TableRelation =
            if ("Account Type" = const(Customer)) "Customer Templ."
            else
            if ("Account Type" = const(Vendor)) "Vendor Templ."
            else
            if ("Account Type" = const(Employee)) "Employee Templ.";
            trigger OnValidate()
            begin
                case "Account Type" of
                    "Account Type"::Customer,
                    "Account Type"::Vendor,
                    "Account Type"::Employee:
                        ;
                    else
                        fielderror("Account Type");
                end;
            end;
        }
        field(7; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
            trigger OnValidate()
            begin
                case "Account Type" of
                    "Account Type"::Customer,
                    "Account Type"::Vendor,
                    "Account Type"::Employee:
                        ;
                    else
                        fielderror("Account Type");
                end;
            end;
        }
        field(8; "Gen. Posting Type"; enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
            trigger OnValidate()
            begin
                TestField("Account Type", "Account Type"::"G/L Account");
            end;

        }
        field(9; "Skip"; Boolean)
        {
            Caption = 'Skip';
        }
        field(11; "Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1), Blocked = const(false));
        }
        field(12; "Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2), Blocked = const(false));
        }
        field(13; "Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Dimension 3 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3), Blocked = const(false));
        }
        field(14; "Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Dimension 4 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4), Blocked = const(false));
        }
    }
    keys
    {
        key(PK; "From Account No.", "From SubAccount No.")
        {
            Clustered = true;
        }
    }
    var
        CsvBuffer: Record "CSV Buffer" temporary;
        RowNo: Integer;
        ColumnNo: Integer;

    procedure Initialize(Rec: Record "wanaStart Map Account")
    var
        ImportFromExcelTitle: Label 'Import FEC File';
        ExcelFileCaption: Label 'FEC Files (*.txt)';
        ExcelFileExtensionTok: Label '.txt', Locked = true;
        IStream: InStream;
        FileName: Text;
        CompanyInformation: Record "Company Information";
    begin
        if UploadIntoStream('', '', '', FileName, IStream) then begin
            CompanyInformation.Get();
            if FileName.Substring(1, 9) <> DELCHR(CompanyInformation."VAT Registration No.").Substring(5, 9) then
                CompanyInformation.TestField("VAT Registration No.", FileName.Substring(1, 9));

            CsvBuffer.LOCKTABLE;
            CsvBuffer.LoadDataFromStream(IStream, '|', '"');
            AnalyzeData();
            CsvBuffer.DeleteAll();
        end;
    end;

    local procedure AnalyzeData()
    var
        lLineNo: Integer;
        lNext: Integer;
        lCount: Integer;
        lProgress: Integer;
        lDialog: Dialog;
        ltAnalyzing: Label 'Analyzing Data...\\';
    begin
        lDialog.Open(ltAnalyzing + '@1@@@@@@@@@@@@@@@@@@@@@@@@@\');
        lDialog.Update(1, 0);
        CsvBuffer.SetFilter(CsvBuffer."Line No.", '>1');
        CsvBuffer.SetRange(CsvBuffer."Field No.", 5, 8);
        lCount := CsvBuffer.Count;
        if CsvBuffer.FindSet then
            repeat
                Init();
                lLineNo := CsvBuffer."Line No.";
                repeat
                    lProgress += 1;
                    ImportCell(CsvBuffer."Field No.", CsvBuffer.Value);
                    lNext := CsvBuffer.Next;
                until (lNext = 0) or (CsvBuffer."Line No." <> lLineNo);
                if not Get("From Account No.") then
                    Insert();
                lDialog.Update(1, Round(lProgress / lCount * 10000, 1));
            until lNext = 0;
    end;

    local procedure ImportCell(pColumnNo: Integer; pCell: Text)
    begin
        case pColumnNo of
            5: // CompteNum
                "From Account No." := pCell;
            6: // CompteLib
                "From Account Name" := pCell;
            7: // CompteAuxNum
                "From SubAccount No." := pCell;
            8: // CompteAuxLib
                "From Account Name" := pCell;
        end;
    end;

    procedure CreateAccount(pRec: Record "wanaStart Map Account")
    begin
        case pRec."Account Type" of
            "Account Type"::"G/L Account":
                CreateGLAccount(pRec);
            "Account Type"::Customer:
                CreateCustomer(pRec);
            "Account Type"::Vendor:
                CreateVendor(pRec);
            "Account Type"::Employee:
                CreateEmployee(pRec);
        end;
    end;

    local procedure CreateGLAccount(pRec: Record "wanaStart Map Account")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := pRec."From Account No.";
        GLAccount.Name := pRec."From Account Name";
        GLAccount.Insert(true);
    end;

    local procedure CreateCustomer(pRec: Record "wanaStart Map Account")
    var
        Customer: Record Customer;
        Template: Record "Customer Templ.";
    begin
        pRec.TestField("Template Code");
        Template.Get(pRec."Template Code");
        Customer.CopyFromNewCustomerTemplate(Template);
        Customer.Validate("No.", pRec."From Account No.");
        Customer.Validate(Name, pRec."From Account Name");
        Customer.Insert(true);
        Update(pRec, Customer."No.");
    end;

    local procedure CreateVendor(pRec: Record "wanaStart Map Account")
    var
        Vendor: Record Vendor;
        Template: Record "Vendor Templ.";
    //??VendorTemplMgt : Codeunit "Vendor Templ. Mgt.";
    begin
        pRec.TestField("Template Code");
        Template.Get(pRec."Template Code");
        //??Customer.CopyFromNewCustomerTemplate(Template);
        Vendor.Validate("No.", pRec."From Account No.");
        Vendor.Validate(Name, pRec."From Account Name");
        Vendor.Insert(true);
        Update(pRec, Vendor."No.");
    end;

    local procedure CreateEmployee(pRec: Record "wanaStart Map Account")
    var
        Employee: Record Employee;
        Template: Record "Employee Templ.";
    begin
        pRec.TestField("Template Code");
        Template.Get(pRec."Template Code");
        //??Employee.CopyFromNewCustomerTemplate(Template);
        Employee.Validate("No.", pRec."From Account No.");
        Employee.Validate("Last Name", pRec."From Account Name");
        Employee.Insert(true);
        Update(pRec, Employee."No.");
    end;

    local procedure Update(pRec: Record "wanaStart Map Account"; pAccountNo: Code[20])
    var
        lRec: Record "wanaStart Map Account";
    begin
        Rec.Get(pRec."From Account No.");
        Rec."Account No." := pAccountNo;
        Rec.Modify();
    end;
}