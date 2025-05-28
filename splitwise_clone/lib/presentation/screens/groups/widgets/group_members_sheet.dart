import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/group_model.dart';
import '../../../../data/providers/group_provider.dart';
import '../../../../data/providers/auth_provider.dart';

class GroupMembersSheet extends StatelessWidget {
  final GroupModel group;

  const GroupMembersSheet({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    final isAdmin = group.isAdmin(currentUserId!);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Участники группы',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: () {
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: group.members.length,
                  itemBuilder: (context, index) {
                    final memberId = group.members[index];
                    final member = groupProvider.groupMembers[memberId];
                    final memberRole = group.roles[memberId] ?? 'member';
                    final isCurrentUser = memberId == currentUserId;

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          member?.name.substring(0, 1).toUpperCase() ?? '?',
                        ),
                      ),
                      title: Text(
                        member?.name ?? 'Загрузка...',
                        style: isCurrentUser
                            ? const TextStyle(fontWeight: FontWeight.bold)
                            : null,
                      ),
                      subtitle: Text(member?.email ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (memberRole == 'admin')
                            Chip(
                              label: const Text('Админ'),
                              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            ),
                          if (isCurrentUser)
                            const Chip(
                              label: Text('Вы'),
                            ),
                          if (isAdmin && !isCurrentUser)
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                if (memberRole != 'admin')
                                  const PopupMenuItem(
                                    value: 'make_admin',
                                    child: Text('Сделать админом'),
                                  ),
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Text('Удалить из группы'),
                                ),
                              ],
                              onSelected: (value) async {
                                if (value == 'make_admin') {
                                  await groupProvider.updateMemberRole(memberId, 'admin');
                                } else if (value == 'remove') {
                                  await groupProvider.removeMember(memberId);
                                }
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}