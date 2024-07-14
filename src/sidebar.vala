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

    /**
     * Construct a new sidebar.
     */
    public Sidebar () {
      Object ();
    }

    public override void constructed () {
      var model = create_navigation_model (null);
      var tree_model = new Gtk.TreeListModel (model, false, false, create_navigation_model);
      var selection = new Gtk.SingleSelection (tree_model);
      list_view.set_model (selection);
    }
  }
}
