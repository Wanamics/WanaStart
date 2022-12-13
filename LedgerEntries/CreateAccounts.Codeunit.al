codeunit 87103 "wanaStart Create Accounts"
{
    TableNo = "wanaStart Account";
    trigger OnRun()
    begin
        if Rec.FindSet() then
            repeat
                case Rec."Account Type" of
                    Rec."Account Type"::"G/L Account":
                        CreateGLAccount(Rec);
                    Rec."Account Type"::Customer:
                        CreateCustomer(Rec);
                    Rec."Account Type"::Vendor:
                        CreateVendor(Rec);
                    Rec."Account Type"::Employee:
                        CreateEmployee(Rec);
                end;
            until Rec.Next() = 0;
    end;

    local procedure CreateGLAccount(pRec: Record "wanaStart Account")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Validate("No.", CopyStr(pRec."From Account No.", 1, 6));
        GLAccount.Validate(Name, pRec."From Account Name");
        if pRec."VAT Prod. Posting Group" <> '' then
            GLAccount.Validate("VAT Prod. Posting Group", pRec."VAT Prod. Posting Group");
        if not GlAccount.Get(GLAccount."No.") then
            GLAccount.Insert(true);
        Update(pRec, GLAccount."No.");
    end;

    local procedure CreateCustomer(pRec: Record "wanaStart Account")
    var
        Customer: Record Customer;
        Template: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        pRec.TestField("Template Code");
        Template.Get(pRec."Template Code");
        SalesSetup.Get();
        if SalesSetup."Customer Nos." = '' then
            Customer.Validate("No.", pRec."From SubAccount No.");
        Customer.Validate(Name, pRec."From Account Name");
        Customer.Insert(true);
        CustomerTemplMgt.ApplyCustomerTemplate(Customer, Template);
        Update(pRec, Customer."No.");
    end;

    local procedure CreateVendor(pRec: Record "wanaStart Account")
    var
        Vendor: Record Vendor;
        Template: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        pRec.TestField("Template Code");
        Template.Get(pRec."Template Code");
        PurchSetup.Get();
        if PurchSetup."Vendor Nos." = '' then
            Vendor.Validate("No.", pRec."From SubAccount No.");
        Vendor.Validate(Name, pRec."From Account Name");
        Vendor.Insert(true);
        VendorTemplMgt.ApplyVendorTemplate(Vendor, Template);
        Update(pRec, Vendor."No.");
    end;

    local procedure CreateEmployee(pRec: Record "wanaStart Account")
    var
        Employee: Record Employee;
        Template: Record "Employee Templ.";
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
        HRSetup: Record "Human Resources Setup";
    begin
        pRec.TestField("Template Code");
        Template.Get(pRec."Template Code");
        HRSetup.Get();
        if HRSetup."Employee Nos." = '' then
            Employee.Validate("No.", pRec."From SubAccount No.");
        Employee.Validate("Last Name", pRec."From Account Name");
        Employee.Insert(true);
        EmployeeTemplMgt.ApplyEmployeeTemplate(Employee, Template);
        Update(pRec, Employee."No.");
    end;

    local procedure Update(pRec: Record "wanaStart Account"; pAccountNo: Code[20])
    var
        lRec: Record "wanaStart Account";
    begin
        pRec.Get(pRec."From Account No.", pRec."From SubAccount No.");
        pRec."Account No." := pAccountNo;
        pRec.Modify();
    end;
}
