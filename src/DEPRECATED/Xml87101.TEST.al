#if FALSE
namespace Wanamics.WanaStart;

using Microsoft.Finance.GeneralLedger.Account;
using System.Utilities;

xmlport 87101 TEST
{
    Caption = 'TEST';
    FieldSeparator = ';';
    Format = VariableText;
    TableSeparator = '<NewLine><NewLine>';
    TextEncoding = UTF8;

    schema
    {
        textelement(RootNodeName)
        {
            tableelement(Header; Integer)
            {
                SourceTableView = sorting(Number) where(Number = const(1));
                // AutoReplace = false;
                // AutoUpdate = false;
                AutoSave = false;
                textelement(_01) { trigger OnBeforePassVariable() begin _01 := GLAccount.FieldCaption("No."); end; }
                textelement(_02) { trigger OnBeforePassVariable() begin _02 := GLAccount.FieldCaption(Name); end; }
            }
            tableelement(GLAccount; "G/L Account")
            {
                SourceTableView = where("No." = filter('1*'));
                fieldelement(No; GLAccount."No.") { }
                fieldelement(Name; GLAccount.Name) { }
                // trigger OnPreXmlItem()
                // begin
                //     // if currXMLport.Import then
                //     //     currXMLport.Skip();
                // end;
            }
        }
    }
    trigger OnPreXmlPort()
    begin
        if currXMLport.Import and not SkipDone then begin
            currXMLport.Skip();
            SkipDone := true;
        end;
        if currXMLport.Export then
            if FileName.EndsWith('.txt') then
                Filename(Filename.Substring(1, StrLen(FileName) - StrLen('.txt')) + '.csv');
    end;

    var
        SkipDone: Boolean;
}
#endif
