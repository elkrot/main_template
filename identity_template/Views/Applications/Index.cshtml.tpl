<!-- Views/Applications/Index.cshtml -->
@model List<object>
@{
    ViewData["Title"] = "Applications";
}

<div class="container mt-4">
    <div class="d-flex justify-content-between align-items-center">
        <h2>OAuth2 Applications</h2>
        <a href="@Url.Action("Create")" class="btn btn-success">Create New</a>
    </div>

    <table class="table table-striped mt-3">
        <thead>
            <tr>
                <th>Client ID</th>
                <th>Display Name</th>
                <th>Type</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            @foreach (dynamic app in Model)
            {
                <tr>
                    <td>@app.ClientId</td>
                    <td>@app.DisplayName</td>
                    <td>@app.Type</td>
                    <td>
                        <a href="@Url.Action("Edit", new { id = app.ApplicationId })" class="btn btn-sm btn-primary">Edit</a>
                        <form method="post" action="@Url.Action("Delete", new { id = app.ApplicationId })" class="d-inline">
                            <button type="submit" class="btn btn-sm btn-danger" onclick="return confirm('Are you sure?')">Delete</button>
                        </form>
                    </td>
                </tr>
            }
        </tbody>
    </table>
</div>