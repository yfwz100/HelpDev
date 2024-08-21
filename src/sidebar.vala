/* sidebar.vala
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

  /**
   * The sidebar component of the application.
   */
  [GtkTemplate (ui = "/org/gnome/gitlab/HelpDev/sidebar.ui")]
  public class Sidebar : Adw.NavigationPage {

    private DocFactory doc_factory = new DocFactory ();

    /**
     * check whether it's in search mode.
     */
    public bool search_mode { get; set; }

    /**
     * The signal will be emitted when navigation item is selected.
     */
    public signal void link_clicked (string uri);

    // [GtkChild]
    // private unowned Gtk.Stack stack;

    [GtkChild]
    private unowned Gtk.ListView list_view;

    [GtkChild]
    private unowned Gtk.ListView search_view;

    /**
     * Construct a new sidebar.
     */
    public Sidebar () {
      Object ();
    }

    public override void constructed () {
      var selection = new Gtk.SingleSelection (doc_factory.create_doc_tree_model ());
      list_view.model = selection;
    }

    [GtkCallback]
    private string get_visible_child_name () {
      if (search_mode) {
        return "search";
      }
      return "tree";
    }

    [GtkCallback]
    private void on_item_activated (uint pos) {
      var item = list_view.model.get_item (pos);
      if (item == null) {
        warning ("invalid position is activated");
        return;
      }
      var row = item as Gtk.TreeListRow;
      if (row == null) {
        warning ("invalid row");
        return;
      }
      click_link_item (row.item as LinkItem);
    }

    [GtkCallback]
    private void on_search_item_activated (uint pos) {
      var item = search_view.model.get_item (pos);
      if (item == null) {
        warning ("invalid position is activated");
        return;
      }
      click_link_item (item as LinkItem);
    }

    private void click_link_item (LinkItem? item) {
      if (item == null) {
        warning ("invalid link item");
        return;
      }
      warning ("link: %s", item.link);
      link_clicked (item.link);
    }

    [GtkCallback]
    public void on_search (Gtk.SearchEntry entry) {
      search_view.model = new Gtk.SingleSelection (doc_factory.create_symbol_list_model (entry.get_text ()));
    }
  }
}