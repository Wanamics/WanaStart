namespace WanaStart.WanaStart;

tableextension 87100 "WanaStart Import FR Line" extends "WanaStart Import FR Line"
{
    fields
    {
        field(87100; "_External Document No."; Code[35])
        {
            Caption = '_External Document No.';
            DataClassification = ToBeClassified;
        }
        field(87101; "_Applies-to ID"; Code[50])
        {
            Caption = '_Applies-to Id';
            DataClassification = ToBeClassified;
        }
        field(87102; "_Shortcut Dimension 1 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 1 Code"';
            DataClassification = ToBeClassified;
        }
        field(87103; "_Shortcut Dimension 2 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 2 Code"';
            DataClassification = ToBeClassified;
        }
    }
}
