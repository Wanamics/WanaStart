page 87101 "wanaStart Set Accounts"
{
    Caption = 'Set';
    SaveValues = true;
    PageType = StandardDialog; //ConfirmationDialog;
    SourceTable = "wanaStart Map Account";
    layout
    {
        area(content)
        {
            field("Account Type"; Rec."Account Type")
            {
                ApplicationArea = All;
            }
            field("Account No."; Rec."Account No.")
            {
                ApplicationArea = All;
            }
            field(TemplateCode; Rec."Template Code")
            {
                ApplicationArea = All;
            }
            field(Skip; rec.Skip)
            {
                ApplicationArea = All;
            }
        }
    }

    procedure Update(var pRec: Record "wanaStart Map Account")
    begin
        if pRec.FindSet() then
            repeat
                if Rec."Account Type" <> pRec."Account Type" then
                    pRec.Validate("Account Type", Rec."Account Type");
                if (Rec."Account No." <> '') and (Rec."Account No." <> pRec."Account No.") then
                    pRec.Validate("Account No.", Rec."Account No.");
                if (Rec."Template Code" <> '') and (Rec."Template Code" <> pRec."Template Code") then
                    pRec.Validate("Template Code", Rec."Template Code");
                pRec.Modify();
            until pRec.Next() = 0;
    end;
}
