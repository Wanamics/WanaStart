namespace Wanamics.Start;

using System.IO;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;
using System.Security.User;

codeunit 87130 "WanaStart ConfigPackage Events"
{
    Permissions =
        tabledata "Sales Invoice Header" = IM,
        tabledata "Sales Invoice Line" = IM,
        tabledata "Sales Shipment Header" = IM,
        tabledata "Purch. Inv. Header" = IM,
        tabledata "Purch. Inv. Line" = IM,
        tabledata "Purch. Rcpt. Header" = IM,
        tabledata "Sales Cr.Memo Header" = IM,
        tabledata "Sales Cr.Memo Line" = IM,
        tabledata "Purch. Cr. Memo Hdr." = IM,
        tabledata "Purch. Cr. Memo Line" = IM;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Config. Package Management", OnInsertRecordOnBeforeInsertRecRef, '', false, false)]
    local procedure OnInsertRecordOnBeforeInsertRecRef(var RecRef: RecordRef; ConfigPackageRecord: Record "Config. Package Record"; var IsHandled: Boolean)
    begin
        if ForcePermission(RecRef.Number) then begin
            RecRef.Insert();
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Config. Package Management", OnModifyRecordDataFieldsOnBeforeRecRefModify, '', false, false)]
    local procedure OnModifyRecordDataFieldsOnBeforeRecRefModify(var RecRef: RecordRef; ConfigPackageTable: Record "Config. Package Table"; var RecordsModifiedCount: Integer; var IsHandled: Boolean; ConfigPackageRecord: Record "Config. Package Record")
    begin
        if ForcePermission(RecRef.Number) then begin
            RecRef.Modify();
            IsHandled := true;
        end;
    end;

    local procedure ForcePermission(pNumber: Integer): boolean
    begin
        if IsSuperUser() then
            exit(pNumber in [
                    Database::"Sales Invoice Header",
                    Database::"Sales Invoice Line",
                    Database::"Sales Shipment Header",
                    Database::"Purch. Inv. Header",
                    Database::"Purch. Inv. Line",
                    Database::"Purch. Rcpt. Header",
                    Database::"Sales Cr.Memo Header",
                    Database::"Sales Cr.Memo Line",
                    Database::"Purch. Cr. Memo Hdr.",
                    Database::"Purch. Cr. Memo Line"
                ])
    end;

    local procedure IsSuperUser(): Boolean
    begin
        if not AlreadyCheck then begin
            SuperUser := UserPermissions.IsSuper(UserSecurityId());
            AlreadyCheck := true;
        end;
        exit(SuperUser);
    end;

    var
        AlreadyCheck: Boolean;
        SuperUser: Boolean;
        UserPermissions: Codeunit "User Permissions";
}
