
def test_formatting():
    # Simulate the logic from the main script
    name = "גבר גבר עמוקי CS.PRO"
    
    # Escape markdown special characters
    safe_name = name.replace("*", r"\*").replace("_", r"\_")
    
    # Truncate if needed
    if len(safe_name) > 20:
        safe_name = safe_name[:17] + "..."
    
    rank = 14
    score = 8810
    steam_id = 12345
    time_str = "6d ago"
    
    # Simulate the line construction with LRO
    line_original = f"**{rank}.** [{name}](https://steamcommunity.com/profiles/{steam_id}) · **{score:,}** pts · {time_str}"
    line_fixed = f"\u202D**{rank}.** [{safe_name}](https://steamcommunity.com/profiles/{steam_id}) · **{score:,}** pts · {time_str}\u202C"
    
    print("Original (broken in Discord):")
    print(line_original)
    print("\nFixed (with LRO - Left-to-Right Override):")
    print(line_fixed)
    print("\n\\u202D = LRO (forces everything to LTR)")
    print("\\u202C = PDF (Pop Directional Formatting)")
    
    # Verify the LRO is present
    if "\u202D" in line_fixed and "\u202C" in line_fixed:
        print("\nSUCCESS: LRO and PDF characters present.")
        print("LRO forces ALL characters after it to display left-to-right,")
        print("overriding the natural directionality of RTL text.")
    else:
        print("\nFAILURE: LRO/PDF characters missing.")

if __name__ == "__main__":
    test_formatting()
