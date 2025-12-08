
cd backend

dotnet new xunit --framework $framework --name "$($SolutionName).Tests" --output "Presentation\$($SolutionName).Tests"
dotnet sln add "Presentation\$($SolutionName).Tests\$($SolutionName).Tests.csproj"

# Tests -> Application
dotnet add "Presentation\$($SolutionName).Tests\$($SolutionName).Tests.csproj" reference "Core\$($SolutionName).Application\$($SolutionName).Application.csproj"
# Tests -> Persistence
dotnet add "Presentation\$($SolutionName).Tests\$($SolutionName).Tests.csproj" reference "Infrastructure\$($SolutionName).Persistence\$($SolutionName).Persistence.csproj"


New-Item -ItemType Directory -Path "Presentation\$($SolutionName).Tests\Common" -Force
New-Item -ItemType Directory -Path "Presentation\$($SolutionName).Tests\model_1\Commands" -Force
New-Item -ItemType Directory -Path "Presentation\$($SolutionName).Tests\model_1\Queries" -Force

dotnet add "Presentation\$($SolutionName).Tests\$($SolutionName).Tests.csproj" package --framework $framework Microsoft.EntityFrameworkCore.InMemory
dotnet add "Presentation\$($SolutionName).Tests\$($SolutionName).Tests.csproj" package --framework $framework Microsoft.NET.Test.Sdk
dotnet add "Presentation\$($SolutionName).Tests\$($SolutionName).Tests.csproj" package --framework $framework Shouldly
dotnet add "Presentation\$($SolutionName).Tests\$($SolutionName).Tests.csproj" package --framework $framework xunit
dotnet add "Presentation\$($SolutionName).Tests\$($SolutionName).Tests.csproj" package --framework $framework xunit.runner.visualstudio



@" 
using System;
using Microsoft.EntityFrameworkCore;
using $($SolutionName).Domain;
using $($SolutionName).Persistence;

namespace $($SolutionName).Tests.Common
{
    public class $($SolutionName)ContextFactory
    {
        public static Guid UserAId = Guid.NewGuid();
        public static Guid UserBId = Guid.NewGuid();

        public static Guid NoteIdForDelete = Guid.NewGuid();
        public static Guid NoteIdForUpdate = Guid.NewGuid();

        public static $($SolutionName)DbContext Create()
        {
            var options = new DbContextOptionsBuilder<$($SolutionName)DbContext>()
                .UseInMemoryDatabase(Guid.NewGuid().ToString())
                .Options;
            var context = new $($SolutionName)DbContext(options);
            context.Database.EnsureCreated();
            context.model_1.AddRange(
                new Note
                {
                    CreationDate = DateTime.Today,
                    Details = "Details1",
                    EditDate = null,
                    Id = Guid.Parse("A6BB65BB-5AC2-4AFA-8A28-2616F675B825"),
                    Title = "Title1",
                    UserId = UserAId
                },
                new Note
                {
                    CreationDate = DateTime.Today,
                    Details = "Details2",
                    EditDate = null,
                    Id = Guid.Parse("909F7C29-891B-4BE1-8504-21F84F262084"),
                    Title = "Title2",
                    UserId = UserBId
                },
                new Note
                {
                    CreationDate = DateTime.Today,
                    Details = "Details3",
                    EditDate = null,
                    Id = NoteIdForDelete,
                    Title = "Title3",
                    UserId = UserAId
                },
                new Note
                {
                    CreationDate = DateTime.Today,
                    Details = "Details4",
                    EditDate = null,
                    Id = NoteIdForUpdate,
                    Title = "Title4",
                    UserId = UserBId
                }
            );
            context.SaveChanges();
            return context;
        }

        public static void Destroy($($SolutionName)DbContext context)
        {
            context.Database.EnsureDeleted();
            context.Dispose();
        }
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).Tests\Common\$($SolutionName)ContextFactory.cs"
@" 
using AutoMapper;
using System;
using $($SolutionName).Application.Interfaces;
using $($SolutionName).Application.Common.Mappings;
using $($SolutionName).Persistence;
using Xunit;

namespace $($SolutionName).Tests.Common
{
    public class QueryTestFixture : IDisposable
    {
        public $($SolutionName)DbContext Context;
        public IMapper Mapper;

        public QueryTestFixture()
        {
            Context = $($SolutionName)ContextFactory.Create();
            var configurationProvider = new MapperConfiguration(cfg =>
            {
                cfg.AddProfile(new AssemblyMappingProfile(
                    typeof(I$($SolutionName)DbContext).Assembly));
            });
            Mapper = configurationProvider.CreateMapper();
        }

        public void Dispose()
        {
            $($SolutionName)ContextFactory.Destroy(Context);
        }
    }

    [CollectionDefinition("QueryCollection")]
    public class QueryCollection : ICollectionFixture<QueryTestFixture> { }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).Tests\Common\QueryTestFixture.cs"
@" 
using System;
using $($SolutionName).Persistence;

namespace $($SolutionName).Tests.Common
{
    public abstract class TestCommandBase : IDisposable
    {
        protected readonly $($SolutionName)DbContext Context;

        public TestCommandBase()
        {
            Context = $($SolutionName)ContextFactory.Create();
        }

        public void Dispose()
        {
            $($SolutionName)ContextFactory.Destroy(Context);
        }
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).Tests\Common\TestCommandBase.cs"
@" 
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using $($SolutionName).Application.model_1.Commands.CreateNote;
using $($SolutionName).Tests.Common;
using Xunit;

namespace $($SolutionName).Tests.model_1.Commands
{
    public class CreateNoteCommandHandlerTests : TestCommandBase
    {
        [Fact]
        public async Task CreateNoteCommandHandler_Success()
        {
            // Arrange
            var handler = new CreateNoteCommandHandler(Context);
            var noteName = "note name";
            var noteDetails = "note details";

            // Act
            var noteId = await handler.Handle(
                new CreateNoteCommand
                {
                    Title = noteName,
                    Details = noteDetails,
                    UserId = $($SolutionName)ContextFactory.UserAId
                },
                CancellationToken.None);

            // Assert
            Assert.NotNull(
                await Context.model_1.SingleOrDefaultAsync(note =>
                    note.Id == noteId && note.Title == noteName &&
                    note.Details == noteDetails));
        }
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).Tests\model_1\Commands\Create_CommandHandlerTests.cs"


@" 
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using $($SolutionName).Application.Common.Exceptions;
using $($SolutionName).Application.model_1.Commands.DeleteCommand;
using $($SolutionName).Application.model_1.Commands.CreateNote;
using $($SolutionName).Tests.Common;
using Xunit;

namespace Notes.Tests.$($SolutionName).Commands
{
    public class DeleteNoteCommandHandlerTests : TestCommandBase
    {
        [Fact]
        public async Task DeleteNoteCommandHandler_Success()
        {
            // Arrange
            var handler = new DeleteNoteCommandHandler(Context);

            // Act
            await handler.Handle(new DeleteNoteCommand
            {
                Id = $($SolutionName)ContextFactory.NoteIdForDelete,
                UserId = $($SolutionName)ContextFactory.UserAId
            }, CancellationToken.None);

            // Assert
            Assert.Null(Context.model_1.SingleOrDefault(note =>
                note.Id == $($SolutionName)ContextFactory.NoteIdForDelete));
        }

        [Fact]
        public async Task DeleteNoteCommandHandler_FailOnWrongId()
        {
            // Arrange
            var handler = new DeleteNoteCommandHandler(Context);

            // Act
            // Assert
            await Assert.ThrowsAsync<NotFoundException>(async () =>
                await handler.Handle(
                    new DeleteNoteCommand
                    {
                        Id = Guid.NewGuid(),
                        UserId = $($SolutionName)ContextFactory.UserAId
                    },
                    CancellationToken.None));
        }

        [Fact]
        public async Task DeleteNoteCommandHandler_FailOnWrongUserId()
        {
            // Arrange
            var deleteHandler = new DeleteNoteCommandHandler(Context);
            var createHandler = new CreateNoteCommandHandler(Context);
            var noteId = await createHandler.Handle(
                new CreateNoteCommand
                {
                    Title = "NoteTitle",
                    UserId = $($SolutionName)ContextFactory.UserAId
                }, CancellationToken.None);

            // Act
            // Assert
            await Assert.ThrowsAsync<NotFoundException>(async () =>
                await deleteHandler.Handle(
                    new DeleteNoteCommand
                    {
                        Id = noteId,
                        UserId = $($SolutionName)ContextFactory.UserBId
                    }, CancellationToken.None));
        }
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).Tests\model_1\Commands\Delete_CommandHandlerTests.cs"
@" 
using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using $($SolutionName).Application.Common.Exceptions;
using $($SolutionName).Application.model_1.Commands.UpdateNote;
using $($SolutionName).Tests.Common;
using Xunit;

namespace $($SolutionName).Tests.model_1.Commands
{
    public class UpdateNoteCommandHandlerTests : TestCommandBase
    {
        [Fact]
        public async Task UpdateNoteCommandHandler_Success()
        {
            // Arrange
            var handler = new UpdateNoteCommandHandler(Context);
            var updatedTitle = "new title";

            // Act
            await handler.Handle(new UpdateNoteCommand
            {
                Id = NotesContextFactory.NoteIdForUpdate,
                UserId = NotesContextFactory.UserBId,
                Title = updatedTitle
            }, CancellationToken.None);

            // Assert
            Assert.NotNull(await Context.model_1.SingleOrDefaultAsync(note =>
                note.Id == NotesContextFactory.NoteIdForUpdate &&
                note.Title == updatedTitle));
        }

        [Fact]
        public async Task UpdateNoteCommandHandler_FailOnWrongId()
        {
            // Arrange
            var handler = new UpdateNoteCommandHandler(Context);

            // Act
            // Assert
            await Assert.ThrowsAsync<NotFoundException>(async () =>
                await handler.Handle(
                    new UpdateNoteCommand
                    {
                        Id = Guid.NewGuid(),
                        UserId = NotesContextFactory.UserAId
                    },
                    CancellationToken.None));
        }

        [Fact]
        public async Task UpdateNoteCommandHandler_FailOnWrongUserId()
        {
            // Arrange
            var handler = new UpdateNoteCommandHandler(Context);

            // Act
            // Assert
            await Assert.ThrowsAsync<NotFoundException>(async () =>
            {
                await handler.Handle(
                    new UpdateNoteCommand
                    {
                        Id = NotesContextFactory.NoteIdForUpdate,
                        UserId = NotesContextFactory.UserAId
                    },
                    CancellationToken.None);
            });
        }
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).Tests\model_1\Commands\Update_CommandHandlerTests.cs"
@" 
using AutoMapper;
using System;
using System.Threading;
using System.Threading.Tasks;
using $($SolutionName).Application.model_1.Queries.GetNoteDetails;
using $($SolutionName).Persistence;
using $($SolutionName).Tests.Common;
using Shouldly;
using Xunit;

namespace $($SolutionName).Tests.model_1.Queries
{
    [Collection("QueryCollection")]
    public class GetNoteDetailsQueryHandlerTests
    {
        private readonly $($SolutionName)DbContext Context;
        private readonly IMapper Mapper;

        public GetNoteDetailsQueryHandlerTests(QueryTestFixture fixture)
        {
            Context = fixture.Context;
            Mapper = fixture.Mapper;
        }

        [Fact]
        public async Task GetNoteDetailsQueryHandler_Success()
        {
            // Arrange
            var handler = new GetNoteDetailsQueryHandler(Context, Mapper);

            // Act
            var result = await handler.Handle(
                new GetNoteDetailsQuery
                {
                    UserId = NotesContextFactory.UserBId,
                    Id = Guid.Parse("909F7C29-891B-4BE1-8504-21F84F262084")
                },
                CancellationToken.None);

            // Assert
            result.ShouldBeOfType<NoteDetailsVm>();
            result.Title.ShouldBe("Title2");
            result.CreationDate.ShouldBe(DateTime.Today);
        }
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).Tests\model_1\Queries\Get_DetailsQueryHandlerTests.cs"
@" 
using AutoMapper;
using System.Threading;
using System.Threading.Tasks;
using $($SolutionName).Application.model_1.Queries.GetNoteList;
using $($SolutionName).Persistence;
using $($SolutionName).Tests.Common;
using Shouldly;
using Xunit;

namespace $($SolutionName).Tests.model_1.Queries
{
    [Collection("QueryCollection")]
    public class GetNoteListQueryHandlerTests
    {
        private readonly $($SolutionName)DbContext Context;
        private readonly IMapper Mapper;

        public GetNoteListQueryHandlerTests(QueryTestFixture fixture)
        {
            Context = fixture.Context;
            Mapper = fixture.Mapper;
        }

        [Fact]
        public async Task GetNoteListQueryHandler_Success()
        {
            // Arrange
            var handler = new GetNoteListQueryHandler(Context, Mapper);

            // Act
            var result = await handler.Handle(
                new GetNoteListQuery
                {
                    UserId = NotesContextFactory.UserBId
                },
                CancellationToken.None);

            // Assert
            result.ShouldBeOfType<NoteListVm>();
            result.model_1.Count.ShouldBe(2);
        }
    }
}

"@ | Set-Content -Path "Presentation\$($SolutionName).Tests\model_1\Queries\Get_ListQueryHandlerTests.cs"

cd ..

Write-Host " backend test '$($SolutionName)' "