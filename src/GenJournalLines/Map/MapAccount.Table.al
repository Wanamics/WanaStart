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
        field(100; "No. of Lines"; Integer)
        {
            Caption = 'No. of Lines';
            FieldClass = FlowField;
            CalcFormula =
                Count("WanaStart Import FR Line"
                    where(CompteNum = field("From Account No."), CompAuxNum = field("From subAccount No.")));
            Editable = false;
            BlankZero = true;
        }
        field(101; Amount; Decimal)
        {
            Caption = 'Amount';
            FieldClass = FlowField;
            CalcFormula =
                sum("WanaStart Import FR Line".Amount
                    where(CompteNum = field("From Account No."), CompAuxNum = field("From subAccount No.")));
            Editable = false;
            BlankZero = true;
        }
        field(102; "No. of Open Lines"; Integer)
        {
            Caption = 'No. of Open Lines';
            FieldClass = FlowField;
            CalcFormula =
                count("WanaStart Import FR Line"
                    where(CompteNum = field("From Account No."), CompAuxNum = field("From subAccount No."), Open = const(true)));
            Editable = false;
            BlankZero = true;
            Width = 5;
        }
        field(103; "Amount Incl. VAT"; Decimal)
        {
            Caption = 'Amount Incl. VAT';
            FieldClass = FlowField;
            CalcFormula =
                sum("WanaStart Import FR Line".Amount
                    where(CompteNum = field("From Account No."), CompAuxNum = field("From subAccount No."), "Gen. Posting Type" = filter("Purchase" | "Sale")));
            Editable = false;
            BlankZero = true;
        }
        field(104; "VAT Amount"; Decimal)
        {
            Caption = 'VAT Amount';
            FieldClass = FlowField;
            CalcFormula =
                sum("WanaStart Import FR Line"."VAT Amount"
                    where(CompteNum = field("From Account No."), CompAuxNum = field("From subAccount No."), "Gen. Posting Type" = filter("Purchase" | "Sale")));
            Editable = false;
            BlankZero = true;
        }
        field(105; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            Editable = false;
            Width = 5;
        }
        field(106; "G/L Acc. VAT Prod. P. G."; Code[20])
        {
            Caption = 'G/L Acc. VAT Prod. Posting Group';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("G/L Account"."VAT Prod. Posting Group" where("No." = field("Account No.")));
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

    procedure Initialize(Rec: Record "WanaStart Map Account")
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
            Load();
            CsvBuffer.DeleteAll();
        end;
    end;

    local procedure Load()
    var
        lLineNo: Integer;
        lNext: Integer;
        lCount: Integer;
        lProgress: Integer;
        lDialog: Dialog;
        ProgressLbl: Label 'Loading...\\';
    begin
        lDialog.Open(ProgressLbl + '@1@@@@@@@@@@@@@@@@@@@@@@@@@\');
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

    procedure CreateAccount(pRec: Record "WanaStart Map Account")
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

    local procedure CreateGLAccount(pRec: Record "WanaStart Map Account")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := pRec."From Account No.";
        GLAccount.Name := pRec."From Account Name";
        GLAccount.Insert(true);
    end;

    local procedure CreateCustomer(pRec: Record "WanaStart Map Account")
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

    local procedure CreateVendor(pRec: Record "WanaStart Map Account")
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

    local procedure CreateEmployee(pRec: Record "WanaStart Map Account")
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

    local procedure Update(pRec: Record "WanaStart Map Account"; pAccountNo: Code[20])
    var
        lRec: Record "WanaStart Map Account";
    begin
        Rec.Get(pRec."From Account No.");
        Rec."Account No." := pAccountNo;
        Rec.Modify();
    end;

    procedure GetAccountName(): Text
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
        BankAccount: Record "Bank Account";
    begin
        GLAccount.SetLoadFields(Name);
        Customer.SetLoadFields(Name);
        Vendor.SetLoadFields(Name);
        // Employee.SetLoadFields(Name);
        BankAccount.SetLoadFields(Name);
        case Rec."Account Type" of
            Rec."Account Type"::"G/L Account":
                if GLAccount.Get(Rec."Account No.") then
                    exit(GLAccount.Name);
            Rec."Account Type"::Customer:
                if Customer.Get(Rec."Account No.") then
                    exit(Customer.Name);
            Rec."Account Type"::Vendor:
                if Vendor.Get(Rec."Account No.") then
                    Exit(Vendor.Name);
            Rec."Account Type"::Employee:
                if Employee.Get(Rec."Account No.") then
                    exit(Employee.FullName());
            Rec."Account Type"::"Bank Account":
                if BankAccount.Get(Rec."Account No.") then
                    exit(BankAccount.Name);
        end;
    end;

    procedure GetVATBusPostingGroup(): Code[20]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        Customer.SetLoadFields("VAT Bus. Posting Group");
        Vendor.SetLoadFields("VAT Bus. Posting Group");
        case Rec."Account Type" of
            Rec."Account Type"::Customer:
                if Customer.Get(Rec."Account No.") then
                    exit(Customer."VAT Bus. Posting Group");
            Rec."Account Type"::Vendor:
                if Vendor.Get(Rec."Account No.") then
                    exit(Vendor."VAT Bus. Posting Group");
        end;
    end;

    procedure ShowAccount()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        Rec.TestField("Account No.");
        case Rec."Account Type" of
            Rec."Account Type"::Customer:
                begin
                    Customer.Get(Rec."Account No.");
                    Page.RunModal(Page::"Customer Card", Customer, Customer.FieldNo("VAT Bus. Posting Group"));
                end;
            Rec."Account Type"::Vendor:
                begin
                    Vendor.Get(Rec."Account No.");
                    Page.RunModal(Page::"Vendor Card", Vendor, Vendor.FieldNo("VAT Bus. Posting Group"));
                end;
        end;
    end;
    // procedure GetGLAccountVATProdPostingGroup(): Code[20]
    // var
    //     GLAccount: Record "G/L Account";
    // begin
    //     GLAccount.SetLoadFields("VAT Prod. Posting Group");
    //     if GLAccount.Get(Rec."Account No.") then
    //         exit(GLAccount."VAT Prod. Posting Group");
    // end;

    procedure ShowGLAccountCard()
    var
        GLAccount: Record "G/L Account";
    begin
        TestField("Account Type", Rec."Account Type"::"G/L Account");
        TestField("Account No.");
        GLAccount.Get("Account No.");
        Page.RunModal(Page::"G/L Account Card", GLAccount, GLAccount.FieldNo("VAT Prod. Posting Group"));
    end;
}