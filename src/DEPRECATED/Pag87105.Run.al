#if FALSE
namespace WanaStart.WanaStart;

using System.Reflection;

page 87105 "_Run Object"
{
    ApplicationArea = All;
    Caption = 'Run Object';
    PageType = List;
    SourceTable = AllObjWithCaption;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Object Type"; Rec."Object Type")
                {
                }
                field("Object ID"; Rec."Object ID")
                {
                }
                field("Object Name"; Rec."Object Name")
                {
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Run)
            {
                trigger OnAction()
                begin
                    case Rec."Object Type" of
                        Rec."Object Type"::Codeunit:
                            Codeunit.Run(Rec."Object ID");
                        Rec."Object Type"::Page:
                            Page.Run(Rec."Object ID");
                        Rec."Object Type"::Report:
                            Report.Run(Rec."Object ID");
                        Rec."Object Type"::XmlPort:
                            XmlPort.Run(Rec."Object ID");
                    end;
                end;
            }
        }
        area(Promoted)
        {
            actionref(RunPromoted; Run) { }
        }
    }
}
#endif
