/* pref_dialog.vala
 *
 * Copyright 2024 Zhi
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Helpdev {
  [GtkTemplate (ui = "/org/gnome/gitlab/HelpDev/pref_dialog.ui")]
  public class PrefDialog : Adw.PreferencesDialog {

    private class DirItem : Object {
      public string path { set; get; }

      public DirItem (string p) {
        Object (path: p);
      }
    }

    private class DirRow : Adw.ActionRow {

      public signal void deleted ();

      public DirRow (string title) {
        Object (title: title);
      }

      construct {
        var del_btn = new Gtk.Button () {
          icon_name = "edit-delete-symbolic",
          valign = Gtk.Align.CENTER,
          css_classes = { "flat" }
        };
        del_btn.clicked.connect (() => {
          deleted ();
        });
        this.add_suffix (del_btn);
      }
    }

    public ListStore path_list_model = new ListStore (typeof (DirItem));

    [GtkChild]
    private unowned Gtk.ListBox path_list_box;

    [GtkChild]
    private unowned Adw.EntryRow font_entry;

    [GtkChild]
    private unowned Adw.EntryRow mono_font_entry;

    [GtkChild]
    private unowned Adw.SwitchRow custom_font_switch;

    construct {
      var settings = new Settings ("org.gnome.gitlab.HelpDev");

      path_list_box.bind_model (path_list_model, (item) => {
        var it = item as DirItem;
        assert_nonnull (it);
        var row = new DirRow (it.path);
        row.deleted.connect (() => {
          uint idx;
          if (path_list_model.find (it, out idx)) {
            path_list_model.remove (idx);
          }
        });
        return row;
      });
      var paths = settings.get_strv ("doc-paths");
      foreach (var path in paths) {
        path_list_model.append (new DirItem (path));
      }
      path_list_model.items_changed.connect (() => {
        var new_paths = new string[path_list_model.n_items];
        for (uint i=0; i<new_paths.length; i++) {
          var it = path_list_model.get_item (i) as DirItem;
          assert_nonnull (it);
          new_paths[i] = it.path;
        }
        settings.set_strv ("doc-paths", new_paths);
      });

      settings.bind ("custom-font", custom_font_switch, "active", SettingsBindFlags.DEFAULT);
      settings.bind ("font", font_entry, "text", SettingsBindFlags.DEFAULT | SettingsBindFlags.NO_SENSITIVITY);
      settings.bind ("mono-font", mono_font_entry, "text", SettingsBindFlags.DEFAULT | SettingsBindFlags.NO_SENSITIVITY);
    }

    [GtkCallback]
    private void on_path_add () {
      select_folder_async.begin ();
    }

    private async void select_folder_async () {
      try {
        var file_dialog = new Gtk.FileDialog ();
        var file = yield file_dialog.select_folder (this.get_parent () as Gtk.Window, null);
        if (file == null) {
          return;
        }

        path_list_model.append (new DirItem (file.get_path ()));
      } catch (Error err) {
        warning ("error: %s", err.message);
      }
    }
  }
}
