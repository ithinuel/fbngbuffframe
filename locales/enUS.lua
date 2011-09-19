local debug = false;
--@alpha@
debug = true;
--@end-alpha@

local L = LibStub("AceLocale-3.0"):NewLocale("fbngBuffFrame","enUS", true, debug)
if not L then return end

L["Buffs"] = true;
L["Debuffs"] = true;
L["Display parameters"] = true;
L["Elements by line"] = true;
L["High"] = true;
L["Icon size"] = true;
L["Left time"] = true;
L["Left time font size"] = true;
L["Low"] = true;
L["Maximum number of elements to show"] = true;
L["Med"] = true;
L["Padding between elements"] = true;
L["Show / Hide anchor"] = true;
L["Show Blizzard Frame"] = true;
L["Stack counter size"] = true;
L["Status bar width"] = true;
L["Wench"] = "Weapon Enchants";
L["None"] = "Without delay";
L["left"] = true;
L["right"] = true;
