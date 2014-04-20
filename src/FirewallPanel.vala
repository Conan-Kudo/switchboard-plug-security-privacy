// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014 Security & Privacy Plug (http://launchpad.net/your-project)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

public class SecurityPrivacy.FirewallPanel : Gtk.Grid {
    private Gtk.ListStore list_store;
    private Gtk.TreeView view;
    private Gtk.Toolbar list_toolbar;
    private bool loading = false;
    private Gtk.Popover add_popover;

    private enum Columns {
        ACTION,
        PROTOCOL,
        DIRECTION,
        PORTS,
        V6,
        N_COLUMNS
    }

    public FirewallPanel () {
        column_spacing = 12;
        row_spacing = 6;
        margin_bottom = 12;

        var status_grid = new Gtk.Grid ();
        status_grid.column_spacing = 12;
        var status_label = new Gtk.Label ("");
        status_label.set_markup ("<b>%s</b>".printf (_("Firewall Status:")));

        var status_switch = new Gtk.Switch ();
        status_switch.notify["active"].connect (() => {
            if (loading == false) {
                UFWHelpers.set_status (status_switch.active);
            }
        });

        var fake_grid_left = new Gtk.Grid ();
        fake_grid_left.hexpand = true;
        var fake_grid_right = new Gtk.Grid ();
        fake_grid_right.hexpand = true;
        status_grid.attach (status_label, 0, 0, 1, 1);
        status_grid.attach (status_switch, 1, 0, 1, 1);

        attach (fake_grid_left, 0, 0, 1, 1);
        attach (status_grid, 1, 0, 1, 1);
        attach (fake_grid_right, 2, 0, 1, 1);
        sensitive = false;
        lock_button.get_permission ().notify["allowed"].connect (() => {
            loading = true;
            sensitive = lock_button.get_permission ().allowed;
            status_switch.active = UFWHelpers.get_status ();
            list_store.clear ();
            if (status_switch.active == true) {
                foreach (var rule in UFWHelpers.get_rules ()) {
                    add_rule (rule);
                }
            }
            loading = false;
        });

        create_treeview ();
    }

    public void add_rule (UFWHelpers.Rule rule) {
        Gtk.TreeIter iter;
        string action = _("Unknown");
        if (rule.action == UFWHelpers.Rule.Action.ALLOW) {
            action = _("Allow");
        } else if (rule.action == UFWHelpers.Rule.Action.DENY) {
            action = _("Deny");
        } else if (rule.action == UFWHelpers.Rule.Action.REJECT) {
            action = _("Reject");
        } else if (rule.action == UFWHelpers.Rule.Action.LIMIT) {
            action = _("Limit");
        }
        string protocol = _("Unknown");
        if (rule.protocol == UFWHelpers.Rule.Protocol.UDP) {
            protocol = "UDP";
        } else if (rule.protocol == UFWHelpers.Rule.Protocol.TCP) {
            protocol = "TCP";
        }
        string direction = _("Unknown");
        if (rule.direction == UFWHelpers.Rule.Direction.IN) {
            direction = _("In");
        } else if (rule.direction == UFWHelpers.Rule.Direction.OUT) {
            direction = _("Out");
        }
        list_store.append (out iter);
        list_store.set (iter, Columns.ACTION, action, Columns.PROTOCOL, protocol,
                Columns.DIRECTION, direction, Columns.PORTS, rule.ports.replace (":", "-"),
                Columns.V6, rule.is_v6);
    }

    private void create_treeview () {
        list_store = new Gtk.ListStore (Columns.N_COLUMNS, typeof (string),
                typeof (string), typeof (string), typeof (string), typeof (bool));

        // The View:
        view = new Gtk.TreeView.with_model (list_store);
        view.vexpand = true;

        var celltoggle = new Gtk.CellRendererToggle ();
        var cell = new Gtk.CellRendererText ();
        view.insert_column_with_attributes (-1, _("Action"), cell, "text", Columns.ACTION);
        view.insert_column_with_attributes (-1, _("Protocol"), cell, "text", Columns.PROTOCOL);
        view.insert_column_with_attributes (-1, _("Direction"), cell, "text", Columns.DIRECTION);
        view.insert_column_with_attributes (-1, _("Ports"), cell, "text", Columns.PORTS);
        view.insert_column_with_attributes (-1, _("IPv6"), celltoggle, "active", Columns.V6);

        list_toolbar = new Gtk.Toolbar ();
        list_toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        list_toolbar.set_icon_size (Gtk.IconSize.SMALL_TOOLBAR);
        var add_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        add_button.clicked.connect (() => {
            var popover_grid = new Gtk.Grid ();
            popover_grid.margin = 6;
            popover_grid.column_spacing = 12;
            popover_grid.row_spacing = 6;
            add_popover = new Gtk.Popover (add_button);
            add_popover.add (popover_grid);

            var policy_label = new Gtk.Label (_("Action:"));
            var policy_combobox = new Gtk.ComboBoxText ();
            policy_combobox.append_text (_("Allow"));
            policy_combobox.append_text (_("Deny"));
            policy_combobox.append_text (_("Reject"));
            policy_combobox.append_text (_("Limit"));
            policy_combobox.active = 0;

            var protocol_label = new Gtk.Label (_("Protocol:"));
            var protocol_combobox = new Gtk.ComboBoxText ();
            protocol_combobox.append_text (_("Both"));
            protocol_combobox.append_text ("TCP");
            protocol_combobox.append_text ("UDP");
            protocol_combobox.active = 0;

            var direction_label = new Gtk.Label (_("Direction:"));
            var direction_combobox = new Gtk.ComboBoxText ();
            direction_combobox.append_text (_("In"));
            direction_combobox.append_text (_("Out"));
            direction_combobox.active = 0;

            var ports_label = new Gtk.Label (_("Ports:"));
            var ports_entry = new Gtk.Entry ();
            ports_entry.input_purpose = Gtk.InputPurpose.NUMBER;
            ports_entry.placeholder_text = _("%d or %d-%d").printf (80, 80, 85);

            var ip_checkbutton = new Gtk.CheckButton.with_label (_("IPv6"));

            var do_add_button = new Gtk.Button.with_label (_("Add Rule"));
            do_add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            var add_button_grid = new Gtk.Grid ();
            add_button_grid.add (do_add_button);
            add_button_grid.halign = Gtk.Align.END;

            popover_grid.attach (policy_label, 0, 0, 1, 1);
            popover_grid.attach (policy_combobox, 1, 0, 1, 1);
            popover_grid.attach (protocol_label, 0, 1, 1, 1);
            popover_grid.attach (protocol_combobox, 1, 1, 1, 1);
            popover_grid.attach (direction_label, 0, 2, 1, 1);
            popover_grid.attach (direction_combobox, 1, 2, 1, 1);
            popover_grid.attach (ports_label, 0, 3, 1, 1);
            popover_grid.attach (ports_entry, 1, 3, 1, 1);
            popover_grid.attach (ip_checkbutton, 1, 4, 1, 1);
            popover_grid.attach (add_button_grid, 0, 5, 2, 1);

            add_popover.show_all ();
        });

        list_toolbar.insert (add_button, -1);
        var remove_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        list_toolbar.insert (remove_button, -1);

        var view_grid = new Gtk.Grid ();
        var frame = new Gtk.Frame (null);
        frame.add (view);
        view_grid.attach (frame, 0, 0, 1, 1);
        view_grid.attach (list_toolbar, 0, 1, 1, 1);
        attach (view_grid, 1, 1, 1, 1);
    }
}