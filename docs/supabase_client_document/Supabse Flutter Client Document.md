## Flutter Client Library

supabase_flutter

This reference documents every object and method available in Supabase's Flutter library, [supabase-flutter](https://pub.dev/packages/supabase_flutter). You can use supabase-flutter to interact with your Postgres database, listen to database changes, invoke Deno Edge Functions, build login and user management functionality, and manage large files.

We also provide a [supabase](https://pub.dev/packages/supabase) package for non-Flutter projects.

---

---

## Initializing

You can initialize Supabase with the static `initialize()` method of the `Supabase` class.

The Supabase client is your entrypoint to the rest of the Supabase functionality and is the easiest way to interact with everything we offer within the Supabase ecosystem.

### Parameters

- url Required string The unique Supabase URL which is supplied when you create a new project in your project dashboard.
- anonKey Required string The unique Supabase Key which is supplied when you create a new project in your project dashboard.
- headers Optional Map&lt;String, String>
- httpClient Optional Client Custom http client to be used by the Supabase client.
- authOptions Optional FlutterAuthClientOptions Options to change the Auth behaviors.
- postgrestOptions Optional PostgrestClientOptions Options to change the Postgrest behaviors.
- realtimeClientOptions Optional RealtimeClientOptions Options to change the Realtime behaviors.
- storageOptions Optional StorageClientOptions Options to change the Storage behaviors.

```dart
Future<void> main() async {
  await Supabase.initialize(
    url: 'https://xyzcompany.supabase.co',
    anonKey: 'public-anon-key',
  );
  runApp(MyApp());
}

// Get a reference your Supabase client
final supabase = Supabase.instance.client;
```

---

## Upgrade guide

Although `supabase_flutter` v2 brings a few breaking changes, for the most part the public API should be the same with a few minor exceptions. We have brought numerous updates behind the scenes to make the SDK work more intuitively for Flutter and Dart developers.

## Upgrade the client library

Make sure you are using v2 of the client library in your `pubspec.yaml` file.

```yaml
supabase_flutter: ^2.0.0
```

_Optionally_ passing custom configuration to `Supabase.initialize()` is now organized into separate objects:

```dart
await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseKey,
  authFlowType: AuthFlowType.pkce,
  storageRetryAttempts: 10,
  realtimeClientOptions: const RealtimeClientOptions(
    logLevel: RealtimeLogLevel.info,
  ),
);
```

### Auth updates

#### Renaming Provider to OAuthProvider

`Provider` enum is renamed to `OAuthProvider`. Previously the `Provider` symbol often collided with classes in the [provider](https://pub.dev/packages/provider) package and developers needed to add import prefixes to avoid collisions. With the new update, developers can use Supabase and Provider in the same codebase without any import prefixes.

```dart
await supabase.auth.signInWithOAuth(
  OAuthProvider.google,
);
```

#### Sign in with Apple method deprecated

We have removed the [sign_in_with_apple](https://pub.dev/packages/sign_in_with_apple) dependency in v2. This is because not every developer needs to sign in with Apple, and we want to reduce the number of dependencies in the library.

With v2, you can import [sign_in_with_apple](https://pub.dev/packages/sign_in_with_apple) as a separate dependency if you need to sign in with Apple. We have also added `auth.generateRawNonce()` method to easily generate a secure nonce.

```dart
await supabase.auth.signInWithApple();
```

#### Initialization does not await for session refresh

In v1, `Supabase.initialize()` would await for the session to be refreshed before returning. This caused delays in the app's launch time, especially when the app is opened in a poor network environment.

In v2, `Supabase.initialize()` returns immediately after obtaining the session from the local storage, which makes the app launch faster. Because of this, there is no guarantee that the session is valid when the app starts.

If you need to make sure the session is valid, you can access the `isExpired` getter to check if the session is valid. If the session is expired, you can listen to the `onAuthStateChange` event and wait for a new `tokenRefreshed` event to be fired.

```dart
// Session is valid, no check required
final session = supabase.auth.currentSession;
```

#### Removing Flutter Webview dependency for OAuth sign in

In v1, on iOS you could pass a `BuildContext` to the `signInWithOAuth()` method to launch the OAuth flow in a Flutter Webview.

In v2, we have dropped the [webview_flutter](https://pub.dev/packages/webview_flutter) dependency in v2 to allow you to have full control over the UI of the OAuth flow. We now have [native support for Google and Apple sign in](https://supabase.com/docs/reference/dart/auth-signinwithidtoken), so opening an external browser is no longer needed on iOS.

Because of this update, we no longer need the `context` parameter, so we have removed the `context` parameter from the `signInWithOAuth()` method.

```dart
// Opens a webview on iOS.
await supabase.auth.signInWithOAuth(
  OAuthProvider.github,
  authScreenLaunchMode: LaunchMode.inAppWebView,
  context: context,
);
```

#### PKCE is the default auth flow type

[PKCE flow](https://supabase.com/blog/supabase-auth-sso-pkce#introducing-pkce), which is a more secure method for obtaining sessions from deep links, is now the default auth flow for any authentication involving deep links.

```dart
await Supabase.initialize(
  url: 'SUPABASE_URL',
  anonKey: 'SUPABASE_ANON_KEY',
  authFlowType: AuthFlowType.implicit, // set to implicit by default
);
```

#### Auth callback host name parameter removed

`Supabase.initialize()` no longer has the `authCallbackUrlHostname` parameter. The `supabase_flutter` SDK will automatically detect auth callback URLs and handle them internally.

```dart
await Supabase.initialize(
  url: 'SUPABASE_URL',
  anonKey: 'SUPABASE_ANON_KEY',
  authCallbackUrlHostname: 'auth-callback',
);
```

#### SupabaseAuth class removed

The `SupabaseAuth` had an `initialSession` member, which was used to obtain the initial session upon app start. This is now removed, and `currentSession` should be used to access the session at any time.

```dart
// Use `initialSession` to obtain the initial session when the app starts.
final initialSession = await SupabaseAuth.initialSession;
```

### Data methods

#### Insert and return data

We made the query builder immutable, which means you can reuse the same query object to chain multiple filters and get the expected outcome.

```dart
// If you declare a query and chain filters on it
final myQuery = supabase.from('my_table').select();
final foo = await myQuery.eq('some_col', 'foo');
// The `eq` filter above is applied in addition to the following filter
final bar = await myQuery.eq('another_col', 'bar');
```

#### Renaming is and in filter

Because `is` and `in` are [reserved keywords](https://dart.dev/languages/keywords) in Dart, v1 used `is_` and `in_` as query filter names. Users found the underscore confusing, so the query filters are now renamed to `isFilter` and `inFilter`.

```dart
final data = await supabase
  .from('users')
  .select()
  .is_('status', null);
```

```dart
final data = await supabase
  .from('users')
  .select()
  .in_('status', ['ONLINE', 'OFFLINE']);
```

#### Deprecate FetchOption in favor of count() and head() methods

`FetchOption()` on `.select()` is now deprecated, and new `.count()` and `head()` methods are added to the query builder.

`count()` on `.select()` performs the select while also getting the count value, and `.count()` directly on `.from()` performs a head request resulting in only fetching the count value.

```dart
// Request with count option
final res = await supabase.from('cities').select(
      'name',
      const FetchOptions(
        count: CountOption.exact,
      ),
    );
final data = res.data;
final count = res.count;
// Request with count and head option
// obtains the count value without fetching the data.
final res = await supabase.from('cities').select(
      'name',
      const FetchOptions(
        count: CountOption.exact,
        head: true,
      ),
    );
final count = res.count;
```

The `PostgrestException` instance thrown by the API methods has a `code` property. In v1, the `code` property contained the http status code.

In v2, the `code` property contains the [PostgREST error code](https://postgrest.org/en/stable/references/errors.html), which is more useful for debugging.

```dart
try {
  await supabase.from('countries').select();
} on PostgrestException catch (error) {
  error.code; // Contains http status code
}
```

### Realtime methods

Realtime methods contains the biggest breaking changes. Most of these changes are to make the interface more type safe.

We have removed the `.on()` method and replaced it with `.onPostgresChanges()`, `.onBroadcast()`, and three different presence methods.

#### Postgres Changes

Use the new `.onPostgresChanges()` method to listen to realtime changes in the database.

In v1, filters were not strongly typed because they took a `String` type. In v2, `filter` takes an object. Its properties are strictly typed to catch type errors.

The payload of the callback is now typed as well. In `v1`, the payload was returned as `dynamic`. It is now returned as a `PostgresChangePayload` object. The object contains the `oldRecord` and `newRecord` properties for accessing the data before and after the change.

#### Broadcast

Broadcast now uses the dedicated `.onBroadcast()` method, rather than the generic `.on()` method. Because the method is specific to broadcast, it takes fewer properties.

#### Presence

Realtime Presence gets three different methods for listening to three different presence events: `sync`, `join`, and `leave`. This allows the callback to be strictly typed.

---

## Fetch data

Perform a SELECT query on the table or view.

- By default, Supabase projects will return a maximum of 1,000 rows. This setting can be changed in Project API Settings. It's recommended that you keep it low to limit the payload size of accidental or malicious requests. You can use `range()` queries to paginate through your data.
- `select()` can be combined with [Filters](https://supabase.com/docs/reference/dart/using-filters)
- `select()` can be combined with [Modifiers](https://supabase.com/docs/reference/dart/using-modifiers)
- `apikey` is a reserved keyword if you're using the [Supabase Platform](https://supabase.com/docs/guides/platform) and [should be avoided as a column name](https://github.com/supabase/supabase/issues/5465).

### Parameters

- columns Optional String The columns to retrieve, separated by commas. Columns can be renamed when returned with `customName:columnName`

```dart
final data = await supabase
  .from('instruments')
  .select();
```

---

## Insert data

Perform an INSERT into the table or view.

### Parameters

- values Required Map&lt;String, dynamic> or List&lt;Map&lt;String, dynamic>> The values to insert. Pass an object to insert a single row or an array to insert multiple rows.

```dart
await supabase
    .from('cities')
    .insert({'name': 'The Shire', 'country_id': 554});
```

---

## Update data

Perform an UPDATE on the table or view.

- `update()` should always be combined with [Filters](https://supabase.com/docs/reference/dart/using-filters) to target the item(s) you wish to update.

### Parameters

- values Required Map&lt;String, dynamic> The values to update with.

```dart
await supabase
  .from('instruments')
  .update({ 'name': 'piano' })
  .eq('id', 1);
```

---

## Upsert data

Perform an UPSERT on the table or view. Depending on the column(s) passed to `onConflict`, `.upsert()` allows you to perform the equivalent of `.insert()` if a row with the corresponding `onConflict` columns doesn't exist, or if it does exist, perform an alternative action depending on `ignoreDuplicates`.

- Primary keys must be included in `values` to use upsert.

### Parameters

- values Required Map&lt;String, dynamic> or List&lt;Map&lt;String, dynamic>> The values to upsert with. Pass a Map to upsert a single row or an List to upsert multiple rows.
- onConflict Optional String Comma-separated UNIQUE column(s) to specify how duplicate rows are determined. Two rows are duplicates if all the `onConflict` columns are equal.
- ignoreDuplicates Optional bool If `true`, duplicate rows are ignored. If `false`, duplicate rows are merged with existing rows.
- defaultToNull Optional bool Make missing fields default to `null`. Otherwise, use the default value for the column. This only applies when inserting new rows, not when merging with existing rows where ignoreDuplicates is set to false. This also only applies when doing bulk upserts.

```dart
final data = await supabase
  .from('instruments')
  .upsert({ 'id': 1, 'name': 'piano' })
  .select();
```

---

## Delete data

Perform a DELETE on the table or view.

- `delete()` should always be combined with [Filters](https://supabase.com/docs/reference/dart/using-filters) to target the item(s) you wish to delete.
- If you use `delete()` with filters and you have RLS enabled, only rows visible through `SELECT` policies are deleted. Note that by default no rows are visible, so you need at least one `SELECT` / `ALL` policy that makes the rows visible.

```dart
await supabase
  .from('countries')
  .delete()
  .eq('id', 1);
```

---

## Call a Postgres function

Perform a function call.

You can call Postgres functions as Remote Procedure Calls, logic in your database that you can execute from anywhere. Functions are useful when the logic rarely changes—like for password resets and updates.

### Parameters

- fn Required String The function name to call.
- params Optional Map&lt;String, dynamic> The arguments to pass to the function call.

```dart
final data = await supabase
  .rpc('hello_world');
```

---

## Using filters

Filters allow you to only return rows that match certain conditions.

Filters can be used on `select()`, `update()`, `upsert()`, and `delete()` queries.

If a Database function returns a table response, you can also apply filters.

```dart
final data = await supabase
  .from('cities')
  .select('name, country_id')
  .eq('name', 'The Shire');  // Correct
```

```dart
final data = await supabase
  .from('cities')
  .eq('name', 'The Shire')  // Incorrect
  .select('name, country_id');
```

---

## Column is equal to a value

Match only rows where `column` is equal to `value`.

### Parameters

- column Required String The column to filter on.
- value Required Object The value to filter with.

```dart
final data = await supabase
  .from('instruments')
  .select()
  .eq('name', 'viola');
```

---

## Column is not equal to a value

Finds all rows whose value on the stated `column` doesn't match the specified `value`.

### Parameters

- column Required String The column to filter on.
- value Required Object The value to filter with.

```dart
final data = await supabase
  .from('instruments')
  .select('id, name')
  .neq('name', 'viola');
```

---

## Column is greater than a value

Finds all rows whose value on the stated `column` is greater than the specified `value`.

### Parameters

- column Required String The column to filter on.
- value Required Object The value to filter with.

```dart
final data = await supabase
  .from('countries')
  .select()
  .gt('id', 2);
```

---

## Column is greater than or equal to a value

Finds all rows whose value on the stated `column` is greater than or equal to the specified `value`.

### Parameters

- column Required String The column to filter on.
- value Required Object The value to filter with.

```dart
final data = await supabase
  .from('countries')
  .select()
  .gte('id', 2);
```

---

## Column is less than a value

Finds all rows whose value on the stated `column` is less than the specified `value`.

### Parameters

- column Required String The column to filter on.
- value Required Object The value to filter with.

```dart
final data = await supabase
  .from('countries')
  .select()
  .lt('id', 2);
```

---

## Column is less than or equal to a value

Finds all rows whose value on the stated `column` is less than or equal to the specified `value`.

### Parameters

- column Required String The column to filter on.
- value Required Object The value to filter with.

```dart
final data = await supabase
  .from('countries')
  .select()
  .lte('id', 2);
```

---

## Column matches a pattern

Finds all rows whose value in the stated `column` matches the supplied `pattern` (case sensitive).

### Parameters

- column Required String The column to filter on.
- pattern Required String The pattern to match with.

```dart
final data = await supabase
  .from('planets')
  .select()
  .like('name', '%Ea%');
```

---

## Column matches a case-insensitive pattern

Finds all rows whose value in the stated `column` matches the supplied `pattern` (case insensitive).

### Parameters

- column Required String The column to filter on.
- pattern Required String The pattern to match with.

```dart
final data = await supabase
  .from('planets')
  .select()
  .ilike('name', '%ea%');
```

---

## Column is a value

A check for exact equality (null, true, false), finds all rows whose value on the stated `column` exactly match the specified `value`.

### Parameters

- column Required String The column to filter on.
- value Required Object? The value to filter with.

```dart
final data = await supabase
  .from('countries')
  .select()
  .isFilter('name', null);
```

---

## Column is in an array

Finds all rows whose value on the stated `column` is found on the specified `values`.

### Parameters

- column Required String The column to filter on.
- values Required List The List to filter with.

```dart
final data = await supabase
  .from('characters')
  .select()
  .inFilter('name', ['Luke', 'Leia']);
```

---

## Column contains every element in a value

Only relevant for jsonb, array, and range columns. Match only rows where `column` contains every element appearing in `value`.

### Parameters

- column Required String The jsonb, array, or range column to filter on.
- value Required Object The jsonb, array, or range value to filter with.

```dart
final data = await supabase
  .from('issues')
  .select()
  .contains('tags', ['is:open', 'priority:low']);
```

---

## Contained by value

Only relevant for jsonb, array, and range columns. Match only rows where every element appearing in `column` is contained by `value`.

### Parameters

- column Required String The jsonb, array, or range column to filter on.
- value Required Object The jsonb, array, or range value to filter with.

```dart
final data = await supabase
  .from('classes')
  .select('name')
  .containedBy('days', ['monday', 'tuesday', 'wednesday', 'friday']);
```

---

## Greater than a range

Only relevant for range columns. Match only rows where every element in `column` is greater than any element in `range`.

### Parameters

- column Required String The range column to filter on.
- range Required String The range to filter with.

```dart
final data = await supabase
  .from('reservations')
  .select()
  .rangeGt('during', '[2000-01-02 08:00, 2000-01-02 09:00)');
```

---

## Greater than or equal to a range

Only relevant for range columns. Match only rows where every element in `column` is either contained in `range` or greater than any element in `range`.

### Parameters

- column Required String The range column to filter on.
- range Required String The range to filter with.

```dart
final data = await supabase
  .from('reservations')
  .select()
  .rangeGte('during', '[2000-01-02 08:30, 2000-01-02 09:30)');
```

---

## Less than a range

Only relevant for range columns. Match only rows where every element in `column` is less than any element in `range`.

### Parameters

- column Required String The range column to filter on.
- range Required String The range to filter with.

```dart
final data = await supabase
  .from('reservations')
  .select()
  .rangeLt('during', '[2000-01-01 15:00, 2000-01-01 16:00)');
```

---

## Less than or equal to a range

Only relevant for range columns. Match only rows where every element in `column` is either contained in `range` or less than any element in `range`.

### Parameters

- column Required String The range column to filter on.
- range Required String The range to filter with.

```dart
final data = await supabase
  .from('reservations')
  .select()
  .rangeLte('during', '[2000-01-01 15:00, 2000-01-01 16:00)');
```

---

## Mutually exclusive to a range

Only relevant for range columns. Match only rows where `column` is mutually exclusive to `range` and there can be no element between the two ranges.

### Parameters

- column Required String The range column to filter on.
- range Required String The range to filter with.

```dart
final data = await supabase
  .from('reservations')
  .select()
  .rangeAdjacent('during', '[2000-01-01 12:00, 2000-01-01 13:00)');
```

---

## With a common element

Only relevant for array and range columns. Match only rows where `column` and `value` have an element in common.

### Parameters

- column Required String The array or range column to filter on.
- value Required Object The array or range value to filter with.

```dart
final data = await supabase
  .from('issues')
  .select('title')
  .overlaps('tags', ['is:closed', 'severity:high']);
```

---

## Match a string

Finds all rows whose tsvector value on the stated `column` matches to_tsquery(query).

### Parameters

- column Required String The text or tsvector column to filter on.
- query Required String The query text to match with.
- config Optional String The text search configuration to use.
- type Optional TextSearchType Change how the `query` text is interpreted.

---

## Match an associated value

Finds all rows whose columns match the specified `query` object.

### Parameters

- query Required Map&lt;String, dynamic> The object to filter with, with column names as keys mapped to their filter values

```dart
final data = await supabase
  .from('instruments')
  .select()
  .match({ 'id': 2, 'name': 'viola' });
```

---

## Don't match the filter

Finds all rows which doesn't satisfy the filter.

- `.not()` expects you to use the raw [PostgREST syntax](https://postgrest.org/en/stable/api.html#horizontal-filtering-rows) for the filter names and values.

    ```
     .not('name','eq','violin')
     .not('arraycol','cs','{"a","b"}') // Use Postgres array {} for array column and 'cs' for contains.
     .not('rangecol','cs','(1,2]') // Use Postgres range syntax for range column.
     .not('id','in','(6,7)')  // Use Postgres list () and 'in' instead of `inFilter`.
     .not('id','in','(${mylist.join(',')})')  // You can insert a Dart list array.
    ```

### Parameters

- column Required String The column to filter on.
- operator Required String The operator to be negated to filter with, following PostgREST syntax.
- value Optional Object The value to filter with, following PostgREST syntax.

```dart
final data = await supabase
  .from('countries')
  .select()
  .not('name', 'is', null);
```

---

## Match at least one filter

Finds all rows satisfying at least one of the filters.

- `.or()` expects you to use the raw [PostgREST syntax](https://postgrest.org/en/stable/api.html#horizontal-filtering-rows) for the filter names and values.

    ```
     .or('id.in.(6,7),arraycol.cs.{"a","b"}')  // Use Postgres list () and 'in' instead of `inFilter`. Array {} and 'cs' for contains.
     .or('id.in.(${mylist.join(',')}),arraycol.cs.{${mylistArray.join(',')}}')    // You can insert a Dart list for list or array column.
     .or('id.in.(${mylist.join(',')}),rangecol.cs.(${mylistRange.join(',')}]')    // You can insert a Dart list for list or range column.
    ```

### Parameters

- filters Required String The filters to use, following PostgREST syntax
- referencedTable Optional String Set this to filter on referenced tables instead of the parent table

```dart
final data = await supabase
  .from('instruments')
  .select('name')
  .or('id.eq.2,name.eq.cello');
```

---

## Match the filter

Match only rows which satisfy the filter. This is an escape hatch - you should use the specific filter methods wherever possible.

`.filter()` expects you to use the raw [PostgREST syntax](https://postgrest.org/en/stable/api.html#horizontal-filtering-rows) for the filter names and values, so it should only be used as an escape hatch in case other filters don't work.

```
.filter('arraycol','cs','{"a","b"}') // Use Postgres array {} and 'cs' for contains.
.filter('rangecol','cs','(1,2]') // Use Postgres range syntax for range column.
.filter('id','in','(6,7)')  // Use Postgres list () and 'in' for in_ filter.
.filter('id','cs','{${mylist.join(',')}}')  // You can insert a Dart array list.
```

### Parameters

- column Required String The column to filter on.
- operator Required String The operator to filter with, following PostgREST syntax.
- value Required Object The value to filter with, following PostgREST syntax.

```dart
final data = await supabase
  .from('characters')
  .select()
  .filter('name', 'in', '("Ron","Dumbledore")');
```

---

## Using modifiers

Filters work on the row level. That is, they allow you to return rows that only match certain conditions without changing the shape of the rows. Modifiers are everything that don't fit that definition—allowing you to change the format of the response (e.g., returning a CSV string).

Modifiers must be specified after filters. Some modifiers only apply for queries that return rows (e.g., `select()` or `rpc()` on a function that returns a table response).

---

## Return data after inserting

```dart
final data = await supabase
  .from('instruments')
  .upsert({ 'id': 1, 'name': 'piano' })
  .select();
```

---

## Order the results

Orders the result with the specified column.

### Parameters

- column Required String The column to order by.
- ascending Optional bool Whether to order in ascending order. Default is `false`.
- nullsFirst Optional bool Whether to order nulls first. Default is `false`.
- referencedTable Optional String Specify the referenced table when ordering by a column in an embedded resource.

```dart
final data = await supabase
  .from('instruments')
  .select('id, name')
  .order('id', ascending: false);
```

---

## Limit the number of rows returned

Limits the result with the specified count.

### Parameters

- count Required int The maximum number of rows to return.
- referencedTable Optional int Set this to limit rows of referenced tables instead of the parent table.

```dart
final data = await supabase
  .from('instruments')
  .select('name')
  .limit(1);
```

---

## Limit the query to a range

Limits the result to rows within the specified range, inclusive.

### Parameters

- from Required int The starting index from which to limit the result.
- to Required int The last index to which to limit the result.
- referencedTable Optional String Set this to limit rows of referenced tables instead of the parent table.

```dart
final data = await supabase
  .from('instruments')
  .select('name')
  .range(0, 1);
```

---

## Retrieve one row of data

Retrieves only one row from the result. Result must be one row (e.g. using limit), otherwise this will result in an error.

```dart
final data = await supabase
  .from('instruments')
  .select('name')
  .limit(1)
  .single();
```

---

## Retrieve zero or one row of data

```dart
final data = await supabase
  .from('instruments')
  .select()
  .eq('name', 'guzheng')
  .maybeSingle();
```

---

## Retrieve as a CSV

```dart
final data = await supabase
  .from('instruments')
  .select()
  .csv();
```

---

## Using explain

For debugging slow queries, you can get the [Postgres `EXPLAIN` execution plan](https://www.google.com/search?q=%5Bhttps://www.postgresql.org/docs/current/sql-explain.html%5D\(https://www.postgresql.org/docs/current/sql-explain.html\)) of a query using the `explain()` method. This works on any query, even for `rpc()` or writes.

Explain is not enabled by default as it can reveal sensitive information about your database. It's best to only enable this for testing environments but if you wish to enable it for production you can provide additional protection by using a `pre-request` function.

Follow the [Performance Debugging Guide](https://supabase.com/docs/guides/database/debugging-performance) to enable the functionality on your project.

### Parameters

- analyze Optional bool If `true`, the query will be executed and the actual run time will be returned.
- verbose Optional bool If `true`, the query identifier will be returned and `data` will include the output columns of the query.
- settings Optional bool If `true`, include information on configuration parameters that affect query planning.
- buffers Optional bool If `true`, include information on buffer usage.
- wal Optional bool If `true`, include information on WAL record generation.

```dart
final data = await supabase
  .from('instruments')
  .select()
  .explain();
```

---

## Create a new user

Creates a new user.

- By default, the user needs to verify their email address before logging in. To turn this off, disable **Confirm email** in [your project](https://supabase.com/dashboard/project/_/auth/providers).
- **Confirm email** determines if users need to confirm their email address after signing up.
  - If **Confirm email** is enabled, a `user` is returned but `session` is null.
  - If **Confirm email** is disabled, both a `user` and a `session` are returned.
- When the user confirms their email address, they are redirected to the [`SITE_URL`](https://www.google.com/search?q=%5Bhttps://supabase.com/docs/guides/auth/redirect-urls%5D\(https://supabase.com/docs/guides/auth/redirect-urls\)) by default. You can modify your `SITE_URL` or add additional redirect URLs in [your project](https://supabase.com/dashboard/project/_/auth/url-configuration).
- If signUp() is called for an existing confirmed user:
  - When both **Confirm email** and **Confirm phone** (even when phone provider is disabled) are enabled in [your project](https://supabase.com/dashboard/project/_/auth/providers), an obfuscated/fake user object is returned.
  - When either **Confirm email** or **Confirm phone** (even when phone provider is disabled) is disabled, the error message, `User already registered` is returned.

### Parameters

- email Optional String User's email address to be used for email authentication.
- phone Optional String User's phone number to be used for phone authentication.
- password Required String Password to be used for authentication.
- emailRedirectTo Optional String The URL to redirect the user to after they confirm their email address.
- data Optional Map&lt;String, dynamic> The user's metadata to be stored in the user's object.
- captchaToken Optional String The captcha token to be used for captcha verification.
- channel Optional OtpChannel Messaging channel to use (e.g. whatsapp or sms). Defaults to `OtpChannel.sms`.

---

## Listen to auth events

Receive a notification every time an auth event happens.

- Types of auth events: `AuthChangeEvent.passwordRecovery`, `AuthChangeEvent.signedIn`, `AuthChangeEvent.signedOut`, `AuthChangeEvent.tokenRefreshed`, `AuthChangeEvent.userUpdated` and `AuthChangeEvent.userDeleted`

---

## Create an anonymous user

Creates an anonymous user.

- Returns an anonymous user
- It is recommended to set up captcha for anonymous sign-ins to prevent abuse. You can pass in the captcha token in the `options` param.

### Parameters

- data Optional Map&lt;String, dynamic> The user's metadata to be stored in the user's object.
- captchaToken Optional String The captcha token to be used for captcha verification.

```dart
await supabase.auth.signInAnonymously();
```

---

## Sign in a user

Log in an existing user using email or phone number with password.

- Requires either an email and password or a phone number and password.

### Parameters

- email Optional String User's email address to be used for email authentication.
- phone Optional String User's phone number to be used for phone authentication.
- password Required String Password to be used for authentication.
- captchaToken Optional String The captcha token to be used for captcha verification.

---

## Sign in with ID Token

### Parameters

- provider Required OAuthProvider
- idToken Required String The identity token obtained from the third-party provider.
- accessToken Optional String
- nonce Optional String
- captchaToken Optional String The captcha token to be used for captcha verification.

---

## Sign in a user through OTP

- Requires either an email or phone number.
- This method is used for passwordless sign-ins where an OTP is sent to the user's email or phone number.
- If you're using an email, you can configure whether you want the user to receive a magiclink or an OTP.
- If you're using phone, you can configure whether you want the user to receive an OTP.
- The magic link's destination URL is determined by the [`SITE_URL`](https://www.google.com/search?q=%5Bhttps://supabase.com/docs/guides/auth/redirect-urls%5D\(https://supabase.com/docs/guides/auth/redirect-urls\)). You can modify the `SITE_URL` or add additional redirect urls in [your project](https://supabase.com/dashboard/project/_/auth/url-configuration).

### Parameters

- email Optional String Email address to send the magic link or OTP to.
- phone Optional String Phone number to send the OTP to.
- emailRedirectTo Optional String The URL to redirect the user to after they click on the magic link.
- shouldCreateUser Optional bool If set to false, this method will not create a new user. Defaults to true.
- data Optional Map&lt;String, dynamic> The user's metadata to be stored in the user's object.
- captchaToken Optional String The captcha token to be used for captcha verification.
- channel Optional OtpChannel Messaging channel to use (e.g. whatsapp or sms). Defaults to `OtpChannel.sms`.

---

## Sign in a user through OAuth

Signs the user in using third-party OAuth providers.

- This method is used for signing in using a third-party provider.
- Supabase supports many different [third-party providers](https://supabase.com/docs/guides/auth#providers).

### Parameters

- provider Required OAuthProvider The OAuth provider to use for signing in.
- redirectTo Optional String
- scopes Optional String A list of scopes to request from the third-party provider.
- authScreenLaunchMode Optional LaunchMode The launch mode for the auth screen. Defaults to `LaunchMode.platformDefault`.
- queryParams Optional Map&lt;String, String> Additional query parameters to be passed to the OAuth flow.

---

## Sign in a user through SSO

- Before you can call this method you need to [establish a connection](https://supabase.com/docs/guides/auth/sso/auth-sso-saml#managing-saml-20-connections) to an identity provider. Use the [CLI commands](https://supabase.com/docs/reference/cli/supabase-sso) to do this.
- If you've associated an email domain to the identity provider, you can use the `domain` property to start a sign-in flow.
- In case you need to use a different way to start the authentication flow with an identity provider, you can use the `providerId` property. For example:
  - Mapping specific user email addresses with an identity provider.
  - Using different hints to identify the correct identity provider, like a company-specific page, IP address or other tracking information.

### Parameters

- providerId Optional String The ID of the SSO provider to use for signing in.
- domain Optional String The email domain to use for signing in.
- redirectTo Optional String
- captchaToken Optional String The captcha token to be used for captcha verification.
- launchMode Optional LaunchMode The launch mode for the auth screen. Defaults to `LaunchMode.platformDefault`.

---

## Sign out a user

Signs out the current user, if there is a logged in user.

- In order to use the `signOut()` method, the user needs to be signed in first.

### Parameters

- scope Optional SignOutScope Whether to sign out from all devices or just the current device. Defaults to `SignOutScope.local`.

```dart
await supabase.auth.signOut();
```

---

## Verify and log in through OTP

### Parameters

- token Required String The token that user was sent to their email or mobile phone
- type Required OtpType Type of the OTP to verify
- email Optional String Email address that the OTP was sent to
- phone Optional String Phone number that the OTP was sent to
- redirectTo Optional String URI to redirect the user to after the OTP is verified
- captchaToken Optional String The captcha token to be used for captcha verification
- tokenHash Optional String Token used in an email link

---

## Retrieve a session

Returns the session data, if there is an active session.

```dart
final Session? session = supabase.auth.currentSession;
```

---

## Retrieve a new session

- This method will refresh and return a new session whether the current one is expired or not.

```dart
final AuthResponse res = await supabase.auth.refreshSession();
final session = res.session;
```

---

## Retrieve a user

Returns the user data, if there is a logged in user.

```dart
final User? user = supabase.auth.currentUser;
```

---

## Update a user

Updates user data for a logged in user.

- In order to use the `updateUser()` method, the user needs to be signed in first.
- By default, email updates sends a confirmation link to both the user's current and new email. To only send a confirmation link to the user's new email, disable **Secure email change** in your project's [email auth provider settings](https://supabase.com/dashboard/project/_/auth/providers).

### Parameters

- attributes Required UserAttributes Attributes to update for the user.
- emailRedirectTo Optional String The URI to redirect the user to after the email is updated.

```dart
final UserResponse res = await supabase.auth.updateUser(
  UserAttributes(
    email: 'example@email.com',
  ),
);
final User? updatedUser = res.user;
```

---

## Retrieve identities linked to a user

Gets all the identities linked to a user.

- The user needs to be signed in to call `getUserIdentities()`.

```dart
final identities = await supabase.auth.getUserIdentities();
```

---

## Link an identity to a user

Links an oauth identity to an existing user. This method supports the PKCE flow.

- The **Enable Manual Linking** option must be enabled from your [project's authentication settings](https://supabase.com/dashboard/project/_/settings/auth).
- The user needs to be signed in to call `linkIdentity()`.
- If the candidate identity is already linked to the existing user or another user, `linkIdentity()` will fail.

### Parameters

- provider Required OAuthProvider The provider to link the identity to.
- redirectTo Optional String
- scopes Optional String A list of scopes to request from the third-party provider.
- authScreenLaunchMode Optional LaunchMode The launch mode for the auth screen. Defaults to `LaunchMode.platformDefault`.
- queryParams Optional Map&lt;String, String> Additional query parameters to be passed to the OAuth flow.

```dart
await supabase.auth.linkIdentity(OAuthProvider.google);
```

---

## Unlink an identity from a user

Unlinks an identity from a user by deleting it. The user will no longer be able to sign in with that identity once it's unlinked.

- The **Enable Manual Linking** option must be enabled from your [project's authentication settings](https://supabase.com/dashboard/project/_/settings/auth).
- The user needs to be signed in to call `unlinkIdentity()`.
- The user must have at least 2 identities in order to unlink an identity.
- The identity to be unlinked must belong to the user.

### Parameters

- identity Required UserIdentity The user identity to unlink.

```dart
// retrieve all identites linked to a user
final identities = await supabase.auth.getUserIdentities();
// find the google identity
final googleIdentity = identities.firstWhere(
  (element) => element.provider == 'google',
);
// unlink the google identity
await supabase.auth.unlinkIdentity(googleIdentity);
```

---

## Send a password reauthentication nonce

- This method is used together with `updateUser()` when a user's password needs to be updated.
- This method sends a nonce to the user's email. If the user doesn't have a confirmed email address, the method sends the nonce to the user's confirmed phone number instead.

```dart
await supabase.auth.reauthenticate();
```

---

## Resend an OTP

---

## Set the session data

- `setSession()` takes in a refresh token and uses it to get a new session.
- The refresh token can only be used once to obtain a new session.
- [Refresh token rotation](https://supabase.com/docs/guides/cli/config#auth.enable_refresh_token_rotation) is enabled by default on all projects to guard against replay attacks.
- You can configure the [`REFRESH_TOKEN_REUSE_INTERVAL`](https://www.google.com/search?q=%5Bhttps://supabase.com/docs/guides/cli/config%23auth.refresh_token_reuse_interval%5D\(https://supabase.com/docs/guides/cli/config%23auth.refresh_token_reuse_interval\)) which provides a short window in which the same refresh token can be used multiple times in the event of concurrency or offline issues.

### Parameters

- refreshToken Required String Refresh token to use to get a new session.

```dart
final refreshToken = supabase.auth.currentSession?.refreshToken ?? '';
final AuthResponse response = await supabase.auth.setSession(refreshToken);
final session = response.session;
```

---

## Auth MFA

This section contains methods commonly used for Multi-Factor Authentication (MFA) and are invoked behind the `supabase.auth.mfa` namespace.

Currently, we only support time-based one-time password (TOTP) as the 2nd factor. We don't support recovery codes but we allow users to enroll more than 1 TOTP factor, with an upper limit of 10.

Having a 2nd TOTP factor for recovery means the user doesn't have to store their recovery codes. It also reduces the attack surface since the recovery factor is usually time-limited and not a single static code.

Learn more about implementing MFA on your application on our guide [here](https://supabase.com/docs/guides/auth/auth-mfa#overview).

---

## Enroll a factor

Starts the enrollment process for a new Multi-Factor Authentication (MFA) factor. This method creates a new `unverified` factor. To verify a factor, present the QR code or secret to the user and ask them to add it to their authenticator app. The user has to enter the code from their authenticator app to verify it.

- Currently, `totp` is the only supported `factorType`. The returned `id` should be used to create a challenge.
- To create a challenge, see [`mfa.challenge()`](https://www.google.com/search?q=%5Bhttps://supabase.com/docs/reference/dart/auth-mfa-challenge%5D\(https://supabase.com/docs/reference/dart/auth-mfa-challenge\)).
- To verify a challenge, see [`mfa.verify()`](https://www.google.com/search?q=%5Bhttps://supabase.com/docs/reference/dart/auth-mfa-verify%5D\(https://supabase.com/docs/reference/dart/auth-mfa-verify\)).
- To create and verify a challenge in a single step, see [`mfa.challengeAndVerify()`](https://www.google.com/search?q=%5Bhttps://supabase.com/docs/reference/dart/auth-mfa-challengeandverify%5D\(https://supabase.com/docs/reference/dart/auth-mfa-challengeandverify\)).

### Parameters

- factorType Optional String Type of factor being enrolled.
- issuer Optional String Domain which the user is enrolled with.
- friendlyName Optional String Human readable name assigned to the factor.

```dart
final res = await supabase.auth.mfa.enroll(factorType: FactorType.totp);
final qrCodeUrl = res.totp.qrCode;
```

---

## Create a challenge

Prepares a challenge used to verify that a user has access to a MFA factor.

- An [enrolled factor](https://supabase.com/docs/reference/dart/auth-mfa-enroll) is required before creating a challenge.
- To verify a challenge, see [`mfa.verify()`](https://www.google.com/search?q=%5Bhttps://supabase.com/docs/reference/dart/auth-mfa-verify%5D\(https://supabase.com/docs/reference/dart/auth-mfa-verify\)).

### Parameters

- factorId Required String System assigned identifier for authenticator device as returned by enroll

```dart
final res = await supabase.auth.mfa.challenge(
  factorId: '34e770dd-9ff9-416c-87fa-43b31d7ef225',
);
```

---

## Verify a challenge

Verifies a code against a challenge. The verification code is provided by the user by entering a code seen in their authenticator app.

- To verify a challenge, please [create a challenge](https://supabase.com/docs/reference/dart/auth-mfa-challenge) first.

### Parameters

- factorId Required String System assigned identifier for authenticator device as returned by enroll
- challengeId Required String The ID of the challenge to verify
- code Required String The verification code on the user's authenticator app

```dart
final res = await supabase.auth.mfa.verify(
  factorId: '34e770dd-9ff9-416c-87fa-43b31d7ef225',
  challengeId: '4034ae6f-a8ce-4fb5-8ee5-69a5863a7c15',
  code: '123456',
);
```

---

## Create and verify a challenge

Helper method which creates a challenge and immediately uses the given code to verify against it thereafter. The verification code is provided by the user by entering a code seen in their authenticator app.

- An [enrolled factor](https://supabase.com/docs/reference/dart/auth-mfa-enroll) is required before invoking `challengeAndVerify()`.
- Executes [`mfa.challenge()`](https://www.google.com/search?q=%5Bhttps://supabase.com/docs/reference/dart/auth-mfa-challenge%5D\(https://supabase.com/docs/reference/dart/auth-mfa-challenge\)) and [`mfa.verify()`](https://www.google.com/search?q=%5Bhttps://supabase.com/docs/reference/dart/auth-mfa-verify%5D\(https://supabase.com/docs/reference/dart/auth-mfa-verify\)) in a single step.

### Parameters

- factorId Required String System assigned identifier for authenticator device as returned by enroll
- code Required String The verification code on the user's authenticator app

```dart
final res = await supabase.auth.mfa.challengeAndVerify(
  factorId: '34e770dd-9ff9-416c-87fa-43b31d7ef225',
  code: '123456',
);
```

---

## Unenroll a factor

Unenroll removes a MFA factor. A user has to have an `aal2` authenticator level in order to unenroll a `verified` factor.

### Parameters

- factorId Required String System assigned identifier for authenticator device as returned by enroll

```dart
final res = await supabase.auth.mfa.unenroll(
  '34e770dd-9ff9-416c-87fa-43b31d7ef225',
);
```

---

## Get Authenticator Assurance Level

Returns the Authenticator Assurance Level (AAL) for the active session.

- Authenticator Assurance Level (AAL) is the measure of the strength of an authentication mechanism.
- In Supabase, having an AAL of `aal1` means the user has signed in with their first factor, such as email, password, or OAuth sign-in. An AAL of `aal2` means the user has also signed in with their second factor, such as a time-based, one-time-password (TOTP).
- If the user has a verified factor, the `nextLevel` field returns `aal2`. Otherwise, it returns `aal1`.

```dart
final res = supabase.auth.mfa.getAuthenticatorAssuranceLevel();
final currentLevel = res.currentLevel;
final nextLevel = res.nextLevel;
final currentAuthenticationMethods = res.currentAuthenticationMethods;
```

---

## Auth Admin

- Any method under the `supabase.auth.admin` namespace requires a `service_role` key.
- These methods are considered admin methods and should be called on a trusted server. Never expose your `service_role` key in the Flutter app.

```dart
final supabase = SupabaseClient(supabaseUrl, serviceRoleKey);
```

---

## Retrieve a user

Get user by id.

- Fetches the user object from the database based on the user's id.
- The `getUserById()` method requires the user's id which maps to the `auth.users.id` column.

### Parameters

- uid Required String User ID of the user to fetch.

```dart
final res = await supabase.auth.admin.getUserById(userId);
final user = res.user;
```

---

## List all users

Get a list of users.

- Defaults to return 50 users per page.

### Parameters

- page Optional int What page of users to return.
- page Optional int How many users to be returned per page. Defaults to 50.

```dart
// Returns the first 50 users.
final List<User> users = await supabase.auth.admin.listUsers();
```

---

## Create a user

Creates a new user.

- To confirm the user's email address or phone number, set `email_confirm` or `phone_confirm` to true. Both arguments default to false.
- `createUser()` will not send a confirmation email to the user. You can use [`inviteUserByEmail()`](https://www.google.com/search?q=%5Bhttps://supabase.com/docs/reference/dart/auth-admin-inviteuserbyemail%5D\(https://supabase.com/docs/reference/dart/auth-admin-inviteuserbyemail\)) if you want to send them an email invite instead.
- If you are sure that the created user's email or phone number is legitimate and verified, you can set the `email_confirm` or `phone_confirm` param to `true`.

### Parameters

- attributes Required AdminUserAttributes Attributes to create the user with.

---

## Delete a user

Delete a user.

- The `deleteUser()` method requires the user's ID, which maps to the `auth.users.id` column.

### Parameters

- id Required String ID of the user to be deleted.

```dart
await supabase.auth.admin
    .deleteUser('715ed5db-f090-4b8c-a067-640ecee36aa0');
```

---

## Send an email invite link

Sends an invite link to the user's email address.

### Parameters

- email Required String Email address of the user to invite.
- redirectTo Optional String URI to redirect the user to after they open the invite link.
- data Optional Map&lt;String, dynamic> A custom data object to store the user's metadata. This maps to the `auth.users.user_metadata` column.

```dart
final UserResponse res = await supabase.auth.admin
    .inviteUserByEmail('email@example.com');
final User? user = res.user;
```

---

## Generate an email link

Generates email links and OTPs to be sent via a custom email provider.

- The following types can be passed into `generateLink()`: `signup`, `magiclink`, `invite`, `recovery`, `emailChangeCurrent`, `emailChangeNew`, `phoneChange`.
- `generateLink()` only generates the email link for `email_change_email` if the "Secure email change" setting is enabled under the "Email" provider in your Supabase project.
- `generateLink()` handles the creation of the user for `signup`, `invite` and `magiclink`.

### Parameters

- type Required GenerateLinkType The type of invite link to generate.
- email Required String Email address of the user to invite.
- password Optional String
- redirectTo Optional String URI to redirect the user to after they open the invite link.
- data Optional Map&lt;String, dynamic> A custom data object to store the user's metadata. This maps to the `auth.users.user_metadata` column.

---

## Update a user

### Parameters

- uid Required GenerateLinkType User ID of the user to update.
- attributes Required AdminUserAttributes Attributes to update for the user.

```dart
await supabase.auth.admin.updateUserById(
  '6aa5d0d4-2a9f-4483-b6c8-0cf4c6c98ac4',
  attributes: AdminUserAttributes(
    email: 'new@email.com',
  ),
);
```

---

## Invokes a Supabase Edge Function

---

## Listen to database changes

Returns real-time data from your table as a `Stream`.

- Realtime is disabled by default for new tables. You can turn it on by [managing replication](https://supabase.com/docs/guides/realtime/postgres-changes#replication-setup).
- `stream()` will emit the initial data as well as any further change on the database as `Stream<List<Map<String, dynamic>>>` by combining Postgrest and Realtime.
- Takes a list of primary key column names that will be used to update and delete the proper records within the SDK.
- The following filters are available
  - `.eq('column', value)` listens to rows where the column equals the value
  - `.neq('column', value)` listens to rows where the column does not equal the value
  - `.gt('column', value)` listens to rows where the column is greater than the value
  - `.gte('column', value)` listens to rows where the column is greater than or equal to the value
  - `.lt('column', value)` listens to rows where the column is less than the value
  - `.lte('column', value)` listens to rows where the column is less than or equal to the value
  - `.inFilter('column', [val1, val2, val3])` listens to rows where the column is one of the values

```dart
supabase.from('countries')
  .stream(primaryKey: ['id'])
  .listen((List<Map<String, dynamic>> data) {
    // Do something awesome with the data
});
```

---

## Subscribe to channel

Subscribe to realtime changes in your database.

- Realtime is disabled by default for new tables. You can turn it on by [managing replication](https://supabase.com/docs/guides/realtime/postgres-changes#replication-setup).
- If you want to receive the "previous" data for updates and deletes, you will need to set `REPLICA IDENTITY` to `FULL`, like this: `ALTER TABLE your_table REPLICA IDENTITY FULL;`

---

## Unsubscribe from a channel

Unsubscribes and removes Realtime channel from Realtime client.

- Removing a channel is a great way to maintain the performance of your project's Realtime service as well as your database if you're listening to Postgres changes. Supabase will automatically handle cleanup 30 seconds after a client is disconnected, but unused channels may cause degradation as more clients are simultaneously subscribed.

```dart
final status = await supabase.removeChannel(channel);
```

---

## Unsubscribe from all channels

Unsubscribes and removes all Realtime channels from Realtime client.

- Removing channels is a great way to maintain the performance of your project's Realtime service as well as your database if you're listening to Postgres changes. Supabase will automatically handle cleanup 30 seconds after a client is disconnected, but unused channels may cause degradation as more clients are simultaneously subscribed.

```dart
final statuses = await supabase.removeAllChannels();
```

---

## Retrieve all channels

Returns all Realtime channels.

```dart
final channels = supabase.getChannels();
```

---

## Create a bucket

Creates a new Storage bucket

- Policy permissions required:
  - `buckets` permissions: `insert`
  - `objects` permissions: none
- Refer to the [Storage guide](https://supabase.com/docs/guides/storage/security/access-control) on how access control works

### Parameters

- id Required String A unique identifier for the bucket you are creating.
- bucketOptions Optional BucketOptions A parameter to optionally make the bucket public.

```dart
final String bucketId = await supabase
  .storage
  .createBucket('avatars');
```

---

## Retrieve a bucket

Retrieves the details of an existing Storage bucket.

- Policy permissions required:
  - `buckets` permissions: `select`
  - `objects` permissions: none
- Refer to the [Storage guide](https://supabase.com/docs/guides/storage/security/access-control) on how access control works

### Parameters

- id Required String The unique identifier of the bucket you would like to retrieve.

```dart
final Bucket bucket = await supabase
  .storage
  .getBucket('avatars');
```

---

## List all buckets

Retrieves the details of all Storage buckets within an existing product.

- Policy permissions required:
  - `buckets` permissions: `select`
  - `objects` permissions: none
- Refer to the [Storage guide](https://supabase.com/docs/guides/storage/security/access-control) on how access control works

```dart
final List<Bucket> buckets = await supabase
  .storage
  .listBuckets();
```

---

## Update a bucket

Updates a new Storage bucket

- Policy permissions required:
  - `buckets` permissions: `update`
  - `objects` permissions: none
- Refer to the [Storage guide](https://supabase.com/docs/guides/storage/security/access-control) on how access control works

### Parameters

- id Required String A unique identifier for the bucket you are updating.
- bucketOptions Required BucketOptions A parameter to optionally make the bucket public.

```dart
final String res = await supabase
  .storage
  .updateBucket('avatars', const BucketOptions(public: false));
```

---

## Delete a bucket

Deletes an existing bucket. A bucket can't be deleted with existing objects inside it. You must first `empty()` the bucket.

- Policy permissions required:
  - `buckets` permissions: `select` and `delete`
  - `objects` permissions: none
- Refer to the [Storage guide](https://supabase.com/docs/guides/storage/security/access-control) on how access control works

### Parameters

- id Required String A unique identifier for the bucket you are deleting.

```dart
final String res = await supabase
  .storage
  .deleteBucket('avatars');
```

---

## Empty a bucket

Removes all objects inside a single bucket.

- Policy permissions required:
  - `buckets` permissions: `select`
  - `objects` permissions: `select` and `delete`
- Refer to the [Storage guide](https://supabase.com/docs/guides/storage/security/access-control) on how access control works

### Parameters

- id Required String A unique identifier for the bucket you are emptying.

```dart
final String res = await supabase
  .storage
  .emptyBucket('avatars');
```

---

## Upload a file

Uploads a file to an existing bucket.

- Policy permissions required:
  - `buckets` permissions: none
  - `objects` permissions: `insert`
- Refer to the [Storage guide](https://supabase.com/docs/guides/storage/security/access-control) on how access control works

### Parameters

- path Required String The relative file path. Should be of the format folder/subfolder/filename.png. The bucket must already exist before attempting to update.
- file Required File or Uint8List File object to be stored in the bucket.
- fileOptions Optional FileOptions
- retryAttempts Optional int Sets the retryAttempts parameter set across the storage client. Defaults to 10.
- retryController Optional StorageRetryController Pass a RetryController instance and call `cancel()` to cancel the retry attempts.

```dart
final avatarFile = File('path/to/file');
final String fullPath = await supabase.storage.from('avatars').upload(
      'public/avatar1.png',
      avatarFile,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );
```

---

## Download a file

Downloads a file.

- Policy permissions required:
  - `buckets` permissions: none
  - `objects` permissions: `select`
- Refer to the [Storage guide](https://supabase.com/docs/guides/storage/security/access-control) on how access control works

### Parameters

- path Required String The full path and file name of the file to be downloaded. For example folder/image.png.
- transform Optional TransformOptions Transform the asset before serving it to the client.

```dart
final Uint8List file = await supabase
  .storage
  .from('avatars')
  .download('avatar1.png');
```

---

## List all files in a bucket

Lists all the files within a bucket.

- Policy permissions required:
  - `buckets` permissions: none
  - `objects` permissions: `select`
- Refer to the [Storage guide](https://supabase.com/docs/guides/storage/security/access-control) on how access control works

### Parameters

- path Required String The folder path.
- searchOptions Optional SearchOptions Options for the search operations such as limit and offset.

```dart
final List<FileObject> objects = await supabase
  .storage
  .from('avatars')
  .list();
```

---

## Replace an existing file

Replaces an existing file at the specified path with a new one.

- Policy permissions required:
  - `buckets` permissions: none
  - `objects` permissions: `update` and `select`
- Refer to the [Storage guide](https://supabase.com/docs/guides/storage/security/access-control) on how access control works

### Parameters

- path Required String The relative file path. Should be of the format folder/subfolder/filename.png. The bucket must already exist before attempting to update.
- file Required File or Uint8List File object to be stored in the bucket.
- fileOptions Optional FileOptions
- retryAttempts Optional int Sets the retryAttempts parameter set across the storage client. Defaults to 10.
- retryController Optional StorageRetryController Pass a RetryController instance and call `cancel()` to cancel the retry attempts.

```dart
final avatarFile = File('path/to/local/file');
final String path = await supabase.storage.from('avatars').update(
      'public/avatar1.png',
      avatarFile,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );
```

---

## Move an existing file

Moves an existing file, optionally renaming it at the same time.

- Policy permissions required:
  - `buckets` permissions: none
  - `objects` permissions: `update` and `select`
- Refer to the [Storage guide](https://supabase.com/docs/guides/storage/security/access-control) on how access control works

### Parameters

- fromPath Required String The original file path, including the current file name. For example folder/image.png.
- toPath Required String The new file path, including the new file name. For example folder/image-new.png.

```dart
final String result = await supabase
  .storage
  .from('avatars')
  .move('public/avatar1.png', 'private/avatar2.png');
```

---

## Delete files in a bucket

Deletes files within the same bucket

- Policy permissions required:
  - `buckets` permissions: none
  - `objects` permissions: `delete` and `select`
- Refer to the [Storage guide](https://supabase.com/docs/guides/storage/security/access-control) on how access control works

### Parameters

- paths Required List&lt;String> A list of files to delete, including the path and file name. For example ['folder/image.png'].

```dart
final List<FileObject> objects = await supabase
  .storage
  .from('avatars')
  .remove(['avatar1.png']);
```

---

## Create a signed URL

Create signed url to download file without requiring permissions. This URL can be valid for a set number of seconds.

- Policy permissions required:
  - `buckets` permissions: none
  - `objects` permissions: `select`
- Refer to the [Storage guide](https://supabase.com/docs/guides/storage/security/access-control) on how access control works

### Parameters

- path Required String The file path, including the file name. For example folder/image.png.
- expiresIn Required int The number of seconds until the signed URL expires. For example, 60 for a URL which is valid for one minute.
- transform Optional TransformOptions Transform the asset before serving it to the client.

```dart
final String signedUrl = await supabase
  .storage
  .from('avatars')
  .createSignedUrl('avatar1.png', 60);
```

---

## Retrieve public URL

Retrieve URLs for assets in public buckets

- The bucket needs to be set to public, either via [updateBucket()](https://supabase.com/docs/reference/dart/storage-updatebucket) or by going to Storage on [supabase.com/dashboard](https://supabase.com/dashboard), clicking the overflow menu on a bucket and choosing "Make public"
- Policy permissions required:
  - `buckets` permissions: none
  - `objects` permissions: none
- Refer to the [Storage guide](https://supabase.com/docs/guides/storage/security/access-control) on how access control works

### Parameters

- path Required String The path and name of the file to generate the public URL for. For example folder/image.png.
- transform Optional TransformOptions Transform the asset before serving it to the client.

```dart
final String publicUrl = supabase
  .storage
  .from('public-bucket')
  .getPublicUrl('avatar1.png');
```
