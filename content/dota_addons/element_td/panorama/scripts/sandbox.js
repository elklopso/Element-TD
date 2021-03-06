"use strict";

var free_towers = $("#free_towers")
var god_mode = $("#god_mode")
var pause = $("#pause")
var wave = $("#WaveNumber")
var max_level = 3;
var min_level = 0;

function ToggleFreeTowers() {
    GameEvents.SendCustomGameEventToServer( "sandbox_toggle_free_towers", { "state": free_towers.checked } );
}

function ToggleGodMode() {
    GameEvents.SendCustomGameEventToServer( "sandbox_toggle_god_mode", { "state": god_mode.checked } );
}

function MaxElementsPressed() {
    GameEvents.SendCustomGameEventToServer( "sandbox_max_elements", {} );
}

function FullLifePressed() {
    GameEvents.SendCustomGameEventToServer( "sandbox_full_life", {} );
}

function GetResources()
{
    $('#Gold').text = $('#Gold').text.replace(/\D/g,'');
    $('#Lumber').text = $('#Lumber').text.replace(/\D/g,'');
    $('#Essence').text = $('#Essence').text.replace(/\D/g,'');

    if (parseInt($('#Gold').text) > 9999999)
        $('#Gold').text = "9999999"

    if (parseInt($('#Lumber').text) > 18)
        $('#Lumber').text = "18"

    if (parseInt($('#Essence').text) > 9)
        $('#Essence').text = "9"

    var table = {};
    table['gold'] = $('#Gold').text;
    table['lumber'] = $('#Lumber').text;
    table['essence'] = $('#Essence').text;

    return table;
}

function UpdateResources()
{
    GameEvents.SendCustomGameEventToServer( "sandbox_set_resources", GetResources() );
}

function UpdateElements(msg) {
    $("#light_level").text = msg.light
    $("#dark_level").text = msg.dark
    $("#water_level").text = msg.water
    $("#fire_level").text = msg.fire
    $("#nature_level").text = msg.nature
    $("#earth_level").text = msg.earth
}

function ValueChange(name, amount)
{
    var panel = $("#"+name+"_level");
    if (panel !== null){
        var current_level = parseInt(panel.text)
        var new_level = current_level + parseInt(amount)
        if (new_level <= max_level && new_level >= min_level)
            panel.text = new_level
        else
            if (new_level < min_level)
                panel.text = min_level
            else
                panel.text = max_level
    }

    GameEvents.SendCustomGameEventToServer( "sandbox_set_element", {element : name, level : panel.text} );
}

function SetWave() {
    wave.text = wave.text.replace(/\D/g,'');

    GameEvents.SendCustomGameEventToServer( "sandbox_set_wave", {"wave": wave.text} );
}

function SpawnWave() {
    wave.text = wave.text.replace(/\D/g,'');
    if (parseInt(wave.text) > 56)
        wave.text = 56
    
    GameEvents.SendCustomGameEventToServer( "sandbox_spawn_wave", {"wave": wave.text} );
}

function ClearWavePressed() {
    GameEvents.SendCustomGameEventToServer( "sandbox_clear_wave", {} );
}

function StopWavePressed() {
    GameEvents.SendCustomGameEventToServer( "sandbox_stop_wave", {} );
}

function Pause() {
    GameEvents.SendCustomGameEventToServer( "sandbox_pause", {"state": pause.checked} );
}

/*function SpeedUp() {
    GameEvents.SendCustomGameEventToServer( "sandbox_speed_up", {"state": speed_up.checked} );
}*/

function EndGame() {
    GameEvents.SendCustomGameEventToServer( "sandbox_end", {} );
}

function HoverEnableSandbox() {
    $("#New").AddClass('hide')
    if ($("#SandboxPanel").BHasClass('hide'))
        $.DispatchEvent("DOTAShowTitleTextTooltip", $("#SandboxEnableButton"), "#sandbox_mode_enable", "#sandbox_mode_tooltip");
    else
    {
        $.DispatchEvent("DOTAShowTitleTextTooltip", $("#SandboxEnableButton"), "#sandbox_enable", "#sandbox_mode_on");
    }
}

function EnableSandbox() {
    GameEvents.SendCustomGameEventToServer( "sandbox_enable", {} );
    if ($("#SandboxPanel").BHasClass('hide'))
        $("#SandboxPanel").RemoveClass('hide')
    else
        $('#SandboxPanel').ToggleClass('Minimized')
    $("#CloseButton").AddClass('hide')
    $("#EnableSandboxText").style['color'] = 'gold;'
    $.DispatchEvent("DOTAShowTitleTextTooltip", $("#SandboxEnableButton"), "#sandbox_enable", "#sandbox_mode_on");    
}

function Dismiss() {
    $("#SandboxEnablePanel").AddClass('hide')
}

function SandboxMakeVisible() {
    $("#SandboxEnablePanel").RemoveClass('hide')
}

(function () {
    GameEvents.Subscribe( "sandbox_mode_visible", SandboxMakeVisible);
    GameEvents.Subscribe( "etd_update_elements", UpdateElements );
})();